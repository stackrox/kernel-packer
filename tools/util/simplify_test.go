package util

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSimplify(t *testing.T) {
	tests := []struct {
		title    string
		input    string
		expected string
	}{
		{
			title: "empty string",
		},
		{
			title:    "single word",
			input:    "popcorn",
			expected: "popcorn",
		},
		{
			title:    "words with spaces",
			input:    "hello world",
			expected: "hello-world",
		},
		{
			title:    "surrounding whitespaces",
			input:    "  hello  world  ",
			expected: "--hello--world--",
		},
		{
			title:    "url",
			input:    "https://github.com/stackrox/kernel-packer",
			expected: "https---github.com-stackrox-kernel-packer",
		},
		{
			title:    "emoji",
			input:    "Keep popping those 🌽 🤔 kernels",
			expected: "Keep-popping-those-----kernels",
		},
		{
			title:    "multi line",
			input:    "multi\nline\nstring",
			expected: "multi-line-string",
		},
	}

	for index, test := range tests {
		name := fmt.Sprintf("%d %s", index+1, test.title)
		t.Run(name, func(t *testing.T) {
			actual := SimplifyURL(test.input)
			assert.Equal(t, test.expected, actual)
		})
	}
}
