import importlib
import unittest

from lxml.etree import ParserError
from unittest.mock import patch, Mock, DEFAULT


crawler = importlib.import_module("kernel-crawler")

class TestKernelCrawler(unittest.TestCase):

    """
    Crawling Flatcar kernels empty page results should be ignored and not
    raised further.
    """
    @patch("kernel-crawler.http")
    @patch("kernel-crawler.html")
    @patch("kernel-crawler.sys.exit")
    def test_flatcar_empty_page(self, mock_sys_exit, mock_html, mock_http):
        mock_http.request.return_value = Mock(status_code=201, data="")
        mock_html.fromstring.return_value.xpath.return_value = ["1.0"]
        mock_html.fromstring.side_effect = [DEFAULT, ParserError("Document is empty")]

        # Crawling is fine, the exceptions is ignored
        crawler.crawl("Flatcar")

        mock_html.fromstring.side_effect = [DEFAULT, ParserError("Document is empty")]

        # Ditto
        crawler.crawl("Flatcar-Beta")

        mock_html.fromstring.side_effect = [DEFAULT, Exception("Anything else")]

        # Another type of exceptions triggers exit with status code 1
        crawler.crawl("Flatcar")
        mock_sys_exit.assert_called_once_with(1)


if __name__ == '__main__':
    unittest.main()
