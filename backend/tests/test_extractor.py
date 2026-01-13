"""
Unit tests for the URL feature extraction module.
Tests the extract_features function from app.core.extractor.
"""

import pytest
import pandas as pd
from app.core.extractor import extract_features


class TestExtractFeatures:
    """Test suite for the extract_features function."""

    def test_extract_features_returns_dataframe(self):
        """Test that extract_features returns a pandas DataFrame."""
        url = "https://www.example.com"
        result = extract_features(url)

        assert isinstance(result, pd.DataFrame)
        assert len(result) == 1

    def test_extract_features_columns(self):
        """Test that the DataFrame contains all expected feature columns."""
        url = "https://www.example.com"
        result = extract_features(url)

        expected_columns = [
            "URL_Length", "Num_Dots", "Num_Hyphens", "Num_Underscores",
            "Has_At", "Has_Tilde", "Num_Digits", "Num_Subdomains",
            "Has_IP", "HTTPS"
        ]

        assert list(result.columns) == expected_columns

    def test_url_length_calculation(self):
        """Test URL_Length feature calculation."""
        url = "https://example.com"
        result = extract_features(url)

        assert result["URL_Length"].values[0] == len(url)

    def test_dots_counting(self):
        """Test Num_Dots feature counting."""
        url = "https://sub.domain.example.com"
        result = extract_features(url)

        # Count dots in URL: sub.domain.example.com = 3 dots
        assert result["Num_Dots"].values[0] == 3

    def test_hyphens_counting(self):
        """Test Num_Hyphens feature counting."""
        url = "https://my-suspicious-site.com"
        result = extract_features(url)

        # Count hyphens: my-suspicious-site = 2 hyphens
        assert result["Num_Hyphens"].values[0] == 2

    def test_underscores_counting(self):
        """Test Num_Underscores feature counting."""
        url = "https://site_with_underscores.com"
        result = extract_features(url)

        # Count underscores: site_with_underscores = 2 underscores
        assert result["Num_Underscores"].values[0] == 2

    def test_has_at_symbol_present(self):
        """Test Has_At feature when @ symbol is present."""
        url = "https://user@example.com"
        result = extract_features(url)

        assert result["Has_At"].values[0] == 1

    def test_has_at_symbol_absent(self):
        """Test Has_At feature when @ symbol is absent."""
        url = "https://example.com"
        result = extract_features(url)

        assert result["Has_At"].values[0] == 0

    def test_has_tilde_present(self):
        """Test Has_Tilde feature when ~ symbol is present."""
        url = "https://example.com/~user"
        result = extract_features(url)

        assert result["Has_Tilde"].values[0] == 1

    def test_has_tilde_absent(self):
        """Test Has_Tilde feature when ~ symbol is absent."""
        url = "https://example.com"
        result = extract_features(url)

        assert result["Has_Tilde"].values[0] == 0

    def test_digits_counting(self):
        """Test Num_Digits feature counting."""
        url = "https://example123.com/page456"
        result = extract_features(url)

        # Count digits: 1,2,3,4,5,6 = 6 digits
        assert result["Num_Digits"].values[0] == 6

    def test_subdomains_counting(self):
        """Test Num_Subdomains feature counting."""
        url = "https://api.v2.example.com"
        result = extract_features(url)

        # api.v2.example.com has 3 dots in domain = 3 subdomains
        assert result["Num_Subdomains"].values[0] == 3

    def test_subdomains_no_subdomain(self):
        """Test Num_Subdomains with no subdomain."""
        url = "https://example.com"
        result = extract_features(url)

        # example.com has 1 dot in domain = 1
        assert result["Num_Subdomains"].values[0] == 1

    def test_has_ip_with_ip_address(self):
        """Test Has_IP feature when domain is an IP address."""
        url = "http://192.168.1.1/page"
        result = extract_features(url)

        assert result["Has_IP"].values[0] == 1

    def test_has_ip_with_domain_name(self):
        """Test Has_IP feature when domain is not an IP address."""
        url = "https://example.com"
        result = extract_features(url)

        assert result["Has_IP"].values[0] == 0

    def test_https_present(self):
        """Test HTTPS feature when URL starts with https://."""
        url = "https://example.com"
        result = extract_features(url)

        assert result["HTTPS"].values[0] == 1

    def test_https_absent(self):
        """Test HTTPS feature when URL starts with http://."""
        url = "http://example.com"
        result = extract_features(url)

        assert result["HTTPS"].values[0] == 0

    def test_complex_phishing_url(self):
        """Test feature extraction on a complex suspicious URL."""
        url = "http://192.168.0.1/~user@login-bank-secure123.php"
        result = extract_features(url)

        # Verify multiple features
        assert result["HTTPS"].values[0] == 0  # No HTTPS
        assert result["Has_IP"].values[0] == 1  # Has IP
        assert result["Has_Tilde"].values[0] == 1  # Has tilde
        assert result["Has_At"].values[0] == 1  # Has at symbol
        assert result["Num_Digits"].values[0] >= 6  # Multiple digits
        assert result["Num_Hyphens"].values[0] >= 2  # Multiple hyphens

    def test_legitimate_url(self):
        """Test feature extraction on a legitimate URL."""
        url = "https://www.google.com/search"
        result = extract_features(url)

        # Verify typical legitimate URL features
        assert result["HTTPS"].values[0] == 1  # Has HTTPS
        assert result["Has_IP"].values[0] == 0  # No IP
        assert result["Has_At"].values[0] == 0  # No at symbol
        assert result["Has_Tilde"].values[0] == 0  # No tilde

    def test_empty_domain_handling(self):
        """Test handling of URLs with empty or missing domain."""
        url = "file:///local/path"
        result = extract_features(url)

        # Should not crash, subdomains should be 0
        assert result["Num_Subdomains"].values[0] == 0

    @pytest.mark.parametrize("url,expected_length", [
        ("https://a.com", 13),
        ("http://example.com", 18),
        ("https://very-long-domain-name-for-testing.com/path", 50),
    ])
    def test_various_url_lengths(self, url, expected_length):
        """Test URL length calculation for various URLs."""
        result = extract_features(url)
        assert result["URL_Length"].values[0] == expected_length
