package reformatters

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"

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
			title: "backport debs remain if 16.04",
			packages: []string{
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50~16.04.1_amd64.deb",
				"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50~16.04.1_amd64.deb",
			},
			manifests: [][]string{
				{
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50_amd64.deb",
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50_amd64.deb",
				},
				{
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-gke-headers-5.4.0-1048_5.4.0-1048.50~16.04.1_amd64.deb",
					"http://security.ubuntu.com/ubuntu/pool/main/l/linux-gke/linux-headers-5.4.0-1048-gke_5.4.0-1048.50~16.04.1_amd64.deb",
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
			assert.ElementsMatch(t, test.manifests, actual)
		})
	}
}

func TestReformatCOS(t *testing.T) {
	packages := []string{
		"https://storage.googleapis.com/cos-tools/13310.1308.6/kernel-headers.tgz",
		"https://storage.googleapis.com/cos-tools/12871.1245.6/kernel-src.tar.gz",
		"https://storage.googleapis.com/cos-tools/13310.1308.6/kernel-src.tar.gz",
		"https://storage.googleapis.com/cos-tools/13310.1260.26/kernel-src.tar.gz",
		"https://storage.googleapis.com/cos-tools/13310.1260.26/kernel-headers.tgz",
	}

	groups, err := reformatCOS(packages)
	require.NoError(t, err)

	expectedGroups := [][]string{
		{
			"https://storage.googleapis.com/cos-tools/12871.1245.6/kernel-src.tar.gz",
		},
		{
			"https://storage.googleapis.com/cos-tools/13310.1308.6/kernel-src.tar.gz",
			"https://storage.googleapis.com/cos-tools/13310.1308.6/kernel-headers.tgz",
		},
		{
			"https://storage.googleapis.com/cos-tools/13310.1260.26/kernel-src.tar.gz",
			"https://storage.googleapis.com/cos-tools/13310.1260.26/kernel-headers.tgz",
		},
	}

	assert.ElementsMatch(t, expectedGroups, groups)
}

func TestReformatSuse(t *testing.T) {
	packages := []string{
		"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update/noarch/kernel-devel-5.3.18-150300.59.43.1.noarch.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update/noarch/kernel-devel-5.3.18-150300.59.46.1.noarch.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update/x86_64/kernel-default-devel-5.3.18-150300.59.43.1.x86_64.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update/x86_64/kernel-default-devel-5.3.18-150300.59.46.1.x86_64.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP1/x86_64/update/noarch/kernel-devel-4.12.14-197.10.1.noarch.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP1/x86_64/update/x86_64/kernel-default-devel-4.12.14-197.10.1.x86_64.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-SERVER/12-SP5/x86_64/update/x86_64/kernel-default-devel-4.12.14-122.103.1.x86_64.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-SERVER/12-SP5/x86_64/update/noarch/kernel-devel-4.12.14-122.103.1.noarch.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP2/x86_64/update/noarch/kernel-devel-5.3.18-24.75.2.noarch.rpm",
		"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP2/x86_64/update/x86_64/kernel-default-devel-5.3.18-24.75.3.x86_64.rpm",
	}

	groups, err := reformatSuse(packages)
	require.NoError(t, err)

	expectedGroups := [][]string{
		{
			"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update/noarch/kernel-devel-5.3.18-150300.59.43.1.noarch.rpm",
			"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update/x86_64/kernel-default-devel-5.3.18-150300.59.43.1.x86_64.rpm",
		},
		{
			"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update/noarch/kernel-devel-5.3.18-150300.59.46.1.noarch.rpm",
			"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP3/x86_64/update/x86_64/kernel-default-devel-5.3.18-150300.59.46.1.x86_64.rpm",
		},
		{
			"https://updates.suse.com/SUSE/Updates/SLE-SERVER/12-SP5/x86_64/update/x86_64/kernel-default-devel-4.12.14-122.103.1.x86_64.rpm",
			"https://updates.suse.com/SUSE/Updates/SLE-SERVER/12-SP5/x86_64/update/noarch/kernel-devel-4.12.14-122.103.1.noarch.rpm",
		},
		{
			"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP1/x86_64/update/noarch/kernel-devel-4.12.14-197.10.1.noarch.rpm",
			"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP1/x86_64/update/x86_64/kernel-default-devel-4.12.14-197.10.1.x86_64.rpm",
		},
		{
			"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP2/x86_64/update/noarch/kernel-devel-5.3.18-24.75.2.noarch.rpm",
			"https://updates.suse.com/SUSE/Updates/SLE-Module-Basesystem/15-SP2/x86_64/update/x86_64/kernel-default-devel-5.3.18-24.75.3.x86_64.rpm",
		},
	}

	assert.ElementsMatch(t, expectedGroups, groups)
}

func TestReformatAzureFips(t *testing.T) {
	packages := []string{
		"---esm.ubuntu.com-fips-ubuntu-pool-main-l-linux-azure-fips-linux-azure-fips-headers-4.15.0-1002_4.15.0-1002.2_all.deb",
		"---esm.ubuntu.com-fips-ubuntu-pool-main-l-linux-azure-fips-linux-headers-4.15.0-1002-azure-fips_4.15.0-1002.2_amd64.deb",
		"---esm.ubuntu.com-fips-ubuntu-pool-main-l-linux-azure-fips-linux-azure-fips-headers-4.15.0-1002_4.15.0-1002.2_all.deb",
		"---esm.ubuntu.com-fips-ubuntu-pool-main-l-linux-azure-fips-linux-headers-4.15.0-1002-azure-fips_4.15.0-1002.2_amd64.deb",
	}

	groups, err := reformatAzureFips(packages)
	require.NoError(t, err)

	expectedGroups := [][]string{
		{
			"---esm.ubuntu.com-fips-ubuntu-pool-main-l-linux-azure-fips-linux-azure-fips-headers-4.15.0-1002_4.15.0-1002.2_all.deb",
			"---esm.ubuntu.com-fips-ubuntu-pool-main-l-linux-azure-fips-linux-headers-4.15.0-1002-azure-fips_4.15.0-1002.2_amd64.deb",
			"---esm.ubuntu.com-fips-ubuntu-pool-main-l-linux-azure-fips-linux-azure-fips-headers-4.15.0-1002_4.15.0-1002.2_all.deb",
			"---esm.ubuntu.com-fips-ubuntu-pool-main-l-linux-azure-fips-linux-headers-4.15.0-1002-azure-fips_4.15.0-1002.2_amd64.deb",
		},
	}

	assert.ElementsMatch(t, expectedGroups, groups)
}
