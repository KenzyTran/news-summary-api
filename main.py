from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, HttpUrl
from dotenv import load_dotenv
from agents import Agent, Runner, trace
from agents.mcp import MCPServerStdio
import os
import asyncio
from typing import Optional
import logging

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="News Summary API",
    description="API để lấy và tóm tắt nội dung tin tức",
    version="1.0.0"
)

# Request model
class NewsRequest(BaseModel):
    url: HttpUrl
    language: Optional[str] = "vietnamese"  # Ngôn ngữ tóm tắt mặc định

# Response model
class NewsResponse(BaseModel):
    url: str
    summary: str
    status: str
    error: Optional[str] = None

@app.get("/")
async def root():
    return {"message": "News Summary API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/summarize", response_model=NewsResponse)
async def summarize_news(request: NewsRequest):
    """
    Endpoint để lấy và tóm tắt nội dung tin tức
    """
    try:
        logger.info(f"Processing news URL: {request.url}")
        
        # Parameters for MCP servers
        fetch_params = {"command": "uvx", "args": ["mcp-server-fetch"]}
        playwright_params = {"command": "npx", "args": ["@playwright/mcp@latest"]}
        
        # Instructions for the agent
        instructions = f"""
        You browse the internet to accomplish your instructions.
        You are highly capable at browsing the internet independently to accomplish your task, 
        including accepting all cookies and clicking 'not now' as appropriate to get to the content you need.
        
        Your task is to:
        1. Navigate to the provided URL
        2. Extract the main news content
        3. Provide a comprehensive summary in {request.language}
        4. Focus on key facts, important details, and main points
        5. Make the summary clear and informative
        
        If the website requires accepting cookies or dismissing popups, do so automatically.
        Be persistent until you have successfully extracted and summarized the content.
        """
        
        # Run the agent with MCP servers
        async with MCPServerStdio(params=fetch_params, client_session_timeout_seconds=60) as mcp_server_fetch:
            async with MCPServerStdio(params=playwright_params, client_session_timeout_seconds=60) as mcp_server_browser:
                agent = Agent(
                    name="news_summarizer", 
                    instructions=instructions, 
                    model="gpt-4o-mini",
                    mcp_servers=[mcp_server_fetch, mcp_server_browser]
                )
                
                with trace("summarize_news"):
                    result = await Runner.run(
                        agent, 
                        f"Summarize the news content from this URL: {request.url}"
                    )
                    
                    summary = result.final_output
                    
                    logger.info(f"Successfully summarized news from: {request.url}")
                    
                    return NewsResponse(
                        url=str(request.url),
                        summary=summary,
                        status="success"
                    )
                    
    except Exception as e:
        logger.error(f"Error processing news URL {request.url}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing news: {str(e)}"
        )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
