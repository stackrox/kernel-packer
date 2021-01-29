package main

import (
	"compress/gzip"
	"crypto/tls"
	"encoding/json"
	"encoding/xml"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"sort"
	"strings"
)

func main() {
	if err := mainCmd(); err != nil {
		log.Fatalf("redhat: %v", err)
	}
}

type repoInfo struct {
	Name  string `json:"name"`
	Url   string `json:"url"`
	Token string `json:"token"`
}

func mainCmd() error {
	var (
		flagCert             = flag.String("cert", "", "path to client certificate file")
		flagKey              = flag.String("key", "", "path to client key file")
		flagToken            = flag.String("token", "", "authorization token")
		flagBaseURL          = flag.String("base-url", "", "repo base url")
		flagBaseURLsFileJSON = flag.String("repos-file", "", "json file of repos, including name, base url and token")
		flagReposNamesFile   = flag.String("repos-names-file", "", "file containing list of selected repo names to crawl from -repos-file")
	)
	flag.Parse()

	// Create a new HTTP client that can perform client certificate auth.
	client, err := newClient(*flagCert, *flagKey)
	if err != nil {
		return err
	}

	repoInfoByName := make(map[string]repoInfo)
	if *flagBaseURLsFileJSON != "" {
		repoInfoBytes, err := ioutil.ReadFile(*flagBaseURLsFileJSON)
		if err != nil {
			return err
		}
		var repoInfos []repoInfo
		err = json.Unmarshal(repoInfoBytes, &repoInfos)
		if err != nil {
			return err
		}
		for _, info := range repoInfos {
			repoInfoByName[info.Name] = info
		}
	} else {
		repoInfoByName["base-url"] = repoInfo{Name: "base-url", Url: *flagBaseURL, Token: *flagToken}
	}

	if *flagReposNamesFile != "" {
		repoBytes, err := ioutil.ReadFile(*flagReposNamesFile)
		if err != nil {
			return err
		}
		repoNames := strings.Split(string(repoBytes), "\n")
		filteredRepoInfoByName := make(map[string]repoInfo)
		for _, name := range repoNames {
			if info, ok := repoInfoByName[name]; ok {
				filteredRepoInfoByName[name] = info
			}
		}
		repoInfoByName = filteredRepoInfoByName
	}

	var urls []string
	for _, repo := range repoInfoByName {
		kernelUrls, err := getKernelURLs(client, strings.TrimSuffix(repo.Url, "/"), repo.Token)
		if err != nil {
			return err
		}
		urls = append(urls, kernelUrls...)
	}

	// Print a sorted list of all RPM URLs.
	sort.Strings(urls)
	for _, url := range urls {
		fmt.Printf("%s\n", url)
	}
	return nil
}

func getKernelURLs(client *http.Client, baseURL string, token string) ([]string, error) {
	// Contact the repo, and extract the url of the primary metadata archive.
	primaryURL, err := getPrimaryURL(client, baseURL, token)
	if err != nil {
		return nil, err
	}

	// Read the primary metadata archive, and extract all of the kernel-devel RPM package paths.
	urls, err := getRPMURLs(client, baseURL, primaryURL, token)
	if err != nil {
		return nil, err
	}
	return urls, nil
}

func newClient(certFilename string, keyFilename string) (*http.Client, error) {
	if certFilename == "" && keyFilename == "" {
		return &http.Client{}, nil
	}
	// Load client cert/key pair.
	cert, err := tls.LoadX509KeyPair(certFilename, keyFilename)
	if err != nil {
		return nil, err
	}

	// Setup HTTPS client.
	tlsConfig := &tls.Config{
		Certificates:       []tls.Certificate{cert},
		InsecureSkipVerify: true,
	}
	transport := &http.Transport{TLSClientConfig: tlsConfig}
	return &http.Client{Transport: transport}, nil
}

type data struct {
	Location struct {
		Href string `xml:"href,attr"`
	} `xml:"location"`
	Type string `xml:"type,attr"`
}

func getPrimaryURL(client *http.Client, baseURL string, authToken string) (string, error) {
	repoMetadataURL := baseURL + "/repodata/repomd.xml"
	log.Printf("Fetching repo metadata URL %s", repoMetadataURL)
	if authToken != "" {
		repoMetadataURL = repoMetadataURL + "?" + authToken
	}

	resp, err := client.Get(repoMetadataURL)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("GET of %s returned HTTP %d", repoMetadataURL, resp.StatusCode)
	}

	decoder := xml.NewDecoder(resp.Body)
	for {
		t, tokenErr := decoder.Token()
		if tokenErr != nil {
			if tokenErr == io.EOF {
				break
			}
			return "", tokenErr
		}

		switch t := t.(type) {
		case xml.StartElement:
			if t.Name.Local == "data" {
				// Decode the data node.
				var data data
				if err := decoder.DecodeElement(&data, &t); err != nil {
					return "", err
				}

				// Extract the primary metadata URL.
				if data.Type == "primary" {
					return baseURL + "/" + data.Location.Href, nil
				}
			}
		}
	}

	return "", fmt.Errorf("no primary metadata")
}

type pkg struct {
	Name     string `xml:"name"`
	Location struct {
		Href string `xml:"href,attr"`
	} `xml:"location"`
}

func getRPMURLs(client *http.Client, baseURL string, primaryURL string, authToken string) ([]string, error) {
	log.Printf("Fetching repo package metadata URL %s", primaryURL)
	if authToken != "" {
		primaryURL = primaryURL + "?" + authToken
	}
	resp, err := client.Get(primaryURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GET of %s returned HTTP %d", primaryURL, resp.StatusCode)
	}

	gzipReader, err := gzip.NewReader(resp.Body)
	if err != nil {
		return nil, err
	}

	urls := make([]string, 0, 64)

	xmlDecoder := xml.NewDecoder(gzipReader)
	for {
		t, tokenErr := xmlDecoder.Token()
		if tokenErr != nil {
			if tokenErr == io.EOF {
				break
			}
			return nil, tokenErr
		}

		switch t := t.(type) {
		case xml.StartElement:
			if t.Name.Local == "package" {
				var pkg pkg

				// Decode the package node.
				if err := xmlDecoder.DecodeElement(&pkg, &t); err != nil {
					return nil, err
				}

				// Only keep kernel-devel and kernel-default-devel packages.
				if pkg.Name != "kernel-devel" && pkg.Name != "kernel-default-devel" {
					continue
				}

				// Keep this kernel-devel RPM package url.
				urls = append(urls, baseURL+"/"+pkg.Location.Href)
			}
		}
	}

	return urls, nil
}
