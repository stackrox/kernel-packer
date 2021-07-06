package reformatters

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestReformatPairs(t *testing.T) {
	tests := []struct {
		title     string
		packages  []string
		manifests [][]string
	}{
		{
			title:     "empty string",
			packages:  []string{},
			manifests: [][]string{},
		},
		// [http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb
		// http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb
		// http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke-5.4/linux-gke-5.4-headers-5.4.0-1048_5.4.0-1048.50~18.04.1_amd64.deb
		// http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke-5.4/linux-headers-5.4.0-1048-gke_5.4.0-1048.50~18.04.1_amd64.deb]
		{
			title: "pairs of debs",
			packages: []string{
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.5.0-786_5.5.0-786.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.5.0-786-gke_5.5.0-786.50_amd64.deb",
			},
			manifests: [][]string{
				{
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				},
				{
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.5.0-786_5.5.0-786.50_amd64.deb",
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.5.0-786-gke_5.5.0-786.50_amd64.deb",
				},
			},
		},
		{
			title: "backport debs",
			packages: []string{
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.5.0-786_5.5.0-786.50~18.04.1_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.5.0-786-gke_5.5.0-786.50~18.04.1_amd64.deb",
			},
			manifests: [][]string{
				{
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				},
				{
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.5.0-786_5.5.0-786.50~18.04.1_amd64.deb",
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.5.0-786-gke_5.5.0-786.50~18.04.1_amd64.deb",
				},
			},
		},
		{
			title: "regulars trump backport debs",
			packages: []string{
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50~18.04.1_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50~18.04.1_amd64.deb",
			},
			manifests: [][]string{
				{
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				},
			},
		},
		{
			title: "regulars trump backport debs when after",
			packages: []string{
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50~18.04.1_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50~18.04.1_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
			},
			manifests: [][]string{
				{
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				},
			},
		},
	}

	for index, test := range tests {
		name := fmt.Sprintf("%d %s", index+1, test.title)
		t.Run(name, func(t *testing.T) {
			actual, _ := reformatPairs(test.packages)
			assert.Equal(t, test.manifests, actual)
		})
	}
}
