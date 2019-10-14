package main

import (
	"compress/gzip"
	"crypto/tls"
	"encoding/xml"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"sort"
)

func main() {
	if err := mainCmd(); err != nil {
		log.Fatalf("redhat: %v", err)
	}
}

func mainCmd() error {
	var (
		flagCert    = flag.String("cert", "rhel-cert.pem", "path to client certificate file")
		flagKey     = flag.String("key", "rhel-key.pem", "path to client key file")
		flagBaseURL = flag.String("base-url", "", "yum repo base url")
	)
	flag.Parse()

	// Create a new HTTP client that can perform client certificate auth.
	client, err := newClient(*flagCert, *flagKey)
	if err != nil {
		return err
	}

	// Contact the repo, and extract the url of the primary metadata archive.
	primaryURL, err := getPrimaryURL(client, *flagBaseURL)
	if err != nil {
		return err
	}

	// Read the primary metadata archive, and extract all of the karnel-devel RPM package paths.
	urls, err := getRPMURLs(client, *flagBaseURL, primaryURL)
	if err != nil {
		return err
	}

	// Print a sorted list of all RPM URLs.
	sort.Strings(urls)
	for _, url := range urls {
		fmt.Printf("%s\n", url)
	}

	return nil
}

func newClient(certFilename string, keyFilename string) (*http.Client, error) {
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

func getPrimaryURL(client *http.Client, baseURL string) (string, error) {
	repoMetadataURL := baseURL + "/repodata/repomd.xml"

	log.Printf("Fetching repo metadata URL %s", repoMetadataURL)
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

func getRPMURLs(client *http.Client, baseURL string, primaryURL string) ([]string, error) {
	log.Printf("Fetching repo package metadata URL %s", primaryURL)
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

				// Only keep kernel-devel packages.
				if pkg.Name != "kernel-devel" {
					continue
				}

				// Keep this kernel-devel RPM package url.
				urls = append(urls, baseURL+"/"+pkg.Location.Href)
			}
		}
	}

	return urls, nil
}
