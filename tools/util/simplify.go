package util

func SimplifyURLs(urls []string) []string {
	var results = make([]string, len(urls))

	for index, url := range urls {
		results[index] = SimplifyURL(url)
	}

	return results
}

func SimplifyURL(url string) string {
	var result = ""

	for _, char := range url {
		switch {
		case 'a' <= char && char <= 'z':
			fallthrough
		case 'A' <= char && char <= 'Z':
			fallthrough
		case '0' <= char && char <= '9':
			fallthrough
		case '_' == char || '.' == char || '-' == char:
			result += string(char)
		default:
			result += "-"
		}
	}

	return result
}
