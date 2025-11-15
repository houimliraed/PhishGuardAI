import pandas as pd
import re

def extract_features(url: str) -> pd.DataFrame:
    features = {
        
        "URL_Length": len(url),
        "Num_Dots": url.count('.'),
        "Num_hyphens": url.count("-"),
        "Num_UnderScores": url.count("_"),
        "Has_At": 1 if "@" in url else 0,
        "Has_Tilde": 1 if "~" in url else 0,
        "Num_Digits": sum(c.isdigit() for c in url),
        "Num_Subdomains": url.count(".") - 1,
        "Has_Ip": 1 if re.match(r'(\d{1,3}\.){3}\d{1,3}', url) else 0,
        "HTTPS": 1 if url.startswith("https") else 0
    }
    return pd.DataFrame[features]
    