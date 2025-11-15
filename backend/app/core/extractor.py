import pandas as pd
import re
from urllib.parse import urlparse

def extract_features(url: str) -> pd.DataFrame:
    domain = urlparse(url).netloc  
    
    features = {
        "URL_Length": len(url),
        "Num_Dots": url.count('.'),
        "Num_Hyphens": url.count('-'),
        "Num_Underscores": url.count('_'),
        "Has_At": 1 if "@" in url else 0,
        "Has_Tilde": 1 if "~" in url else 0,
        "Num_Digits": sum(c.isdigit() for c in url),
        "Num_Subdomains": domain.count('.') if domain else 0,
        "Has_IP": 1 if re.match(r'^\d{1,3}(\.\d{1,3}){3}$', domain) else 0,
        "HTTPS": 1 if url.startswith("https://") else 0
    }
    
    return pd.DataFrame([features])
