# News Summary API

API để lấy và tóm tắt nội dung tin tức sử dụng FastAPI và MCP (Model Context Protocol).

## Tính năng

- ✅ Lấy nội dung tin tức từ URL
- ✅ Tóm tắt nội dung bằng AI
- ✅ Hỗ trợ nhiều ngôn ngữ
- ✅ API RESTful với FastAPI
- ✅ Triển khai trên Ubuntu server
- ✅ Nginx reverse proxy
- ✅ Systemd service

## Cài đặt

### 1. Cài đặt local (Windows)

```bash
# Clone repository
git clone <your-repo-url>
cd crawl_investing_news

# Tạo virtual environment
python -m venv venv
venv\Scripts\activate

# Cài đặt dependencies
pip install -r requirements.txt

# Cài đặt Playwright
npm install -g @playwright/mcp@latest

# Tạo file .env
copy .env.example .env
# Chỉnh sửa .env và thêm API keys
```

### 2. Triển khai trên Ubuntu Server

```bash
# Upload files lên server
scp -r . user@your-server:/tmp/news-summary-api

# SSH vào server
ssh user@your-server

# Chạy script deploy
cd /tmp/news-summary-api
chmod +x deploy.sh
./deploy.sh
```

## Cấu hình

### Environment Variables (.env)

```env
OPENAI_API_KEY=sk-your-openai-api-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key
HOST=0.0.0.0
PORT=8000
LOG_LEVEL=INFO
```

## Sử dụng API

### 1. Health Check

```bash
curl -X GET "http://localhost:8000/health"
```

### 2. Tóm tắt tin tức

```bash
curl -X POST "http://localhost:8000/summarize" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.investing.com/news/commodities-news/oil-prices-dip-on-us-inventory-build-opec-output-hike-expectations-4121849",
    "language": "vietnamese"
  }'
```

### 3. Sử dụng Python

```python
import requests

# Test API
response = requests.post(
    "http://localhost:8000/summarize",
    json={
        "url": "https://example.com/news-article",
        "language": "vietnamese"
    }
)

result = response.json()
print(result["summary"])
```

## API Documentation

Khi server chạy, truy cập:
- API docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Cấu trúc dự án

```
crawl_investing_news/
├── main.py              # FastAPI application
├── requirements.txt     # Python dependencies
├── .env.example        # Environment variables template
├── deploy.sh           # Ubuntu deployment script
├── test_api.py         # API testing script
├── README.md           # Documentation
└── .vscode/
    └── mcp.json        # MCP configuration
```

## Endpoints

### POST /summarize

**Request:**
```json
{
    "url": "https://example.com/news-article",
    "language": "vietnamese"
}
```

**Response:**
```json
{
    "url": "https://example.com/news-article",
    "summary": "Tóm tắt nội dung tin tức...",
    "status": "success",
    "error": null
}
```

## Monitoring

### Kiểm tra trạng thái service

```bash
# Kiểm tra trạng thái
sudo systemctl status news-summary-api

# Xem logs
sudo journalctl -u news-summary-api -f

# Restart service
sudo systemctl restart news-summary-api
```

### Kiểm tra Nginx

```bash
# Kiểm tra trạng thái Nginx
sudo systemctl status nginx

# Test cấu hình
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

## Troubleshooting

### 1. Lỗi MCP Server

```bash
# Kiểm tra uvx
which uvx

# Cài đặt lại uvx
pip install --user uvx

# Kiểm tra Playwright
npx playwright --version
```

### 2. Lỗi API Key

- Đảm bảo API key được cấu hình trong `.env`
- Kiểm tra quyền truy cập API key

### 3. Lỗi Port

```bash
# Kiểm tra port đang sử dụng
sudo netstat -tulpn | grep :8000

# Kill process nếu cần
sudo kill -9 <process_id>
```

## License

MIT License
