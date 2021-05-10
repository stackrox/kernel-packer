package reformatters

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGardenLinuxUncrawled(t *testing.T) {
	tests := []struct {
		name  string
		input []string
	}{
		{
			name: "working",
			input: []string{
				"http://18.185.215.86/packages/linux-headers-5.4.0-5-common_5.4.68-1_all.deb",
				"http://18.185.215.86/packages/linux-headers-5.4.0-5-cloud-amd64_5.4.68-1_amd64.deb",
				"http://18.185.215.86/packages/linux-kbuild-5.4_5.4.68-1_amd64.deb",
			},
		},
		{
			name: "irregular package name",
			input: []string{
				"http://45.86.152.1/gardenlinux/pool/main/l/linux-signed-amd64/linux-headers-amd64_5.4.93-1_amd64.deb",
				"http://45.86.152.1/gardenlinux/pool/main/l/linux-signed-amd64/linux-headers-cloud-amd64_5.4.93-1_amd64.deb",
				"http://45.86.152.1/gardenlinux/pool/main/l/linux/linux-kbuild-5.4_5.4.93-1_amd64.deb",
			},
		},
	}

	for index, test := range tests {
		name := fmt.Sprintf("%d %s", index+1, test.name)
		t.Run(name, func(t *testing.T) {
			actual, err := reformatDebian(test.input)
			assert.Nil(t, err)
			assert.Equal(t, 1, len(actual))
			assert.ElementsMatch(t, test.input, actual[0])
		})
	}
}
