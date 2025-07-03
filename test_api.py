import requests
import json

# Test the API locally
BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    response = requests.get(f"{BASE_URL}/health")
    print(f"Health check: {response.status_code} - {response.json()}")

def test_summarize():
    """Test summarize endpoint"""
    test_data = {
        "url": "https://www.investing.com/news/commodities-news/oil-prices-dip-on-us-inventory-build-opec-output-hike-expectations-4121849",
        "language": "vietnamese"
    }
    
    response = requests.post(
        f"{BASE_URL}/summarize",
        json=test_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Summarize test: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print(f"Summary: {result['summary'][:200]}...")
    else:
        print(f"Error: {response.text}")

if __name__ == "__main__":
    print("Testing News Summary API...")
    test_health()
    test_summarize()
