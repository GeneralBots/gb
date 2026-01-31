REM Knowledge Base Website Crawler Bot - Start Template
REM Sets up bot context and crawled websites, then exits

REM Load bot introduction
intro = GET BOT MEMORY "introduction"
IF intro = "" THEN
    intro = "I'm your documentation assistant with access to crawled websites."
END IF

REM Register websites for crawling (preprocessing mode)
USE WEBSITE "https://docs.python.org"
USE WEBSITE "https://developer.mozilla.org"
USE WEBSITE "https://stackoverflow.com"

REM Set context for LLM
SET CONTEXT "role" AS intro
SET CONTEXT "capabilities" AS "I can search Python docs, MDN web docs, and Stack Overflow."

REM Configure suggestion buttons
CLEAR SUGGESTIONS
ADD SUGGESTION "python" AS "How do I use Python dictionaries?"
ADD SUGGESTION "javascript" AS "Explain JavaScript async/await"
ADD SUGGESTION "web" AS "What is the DOM in web development?"

REM Initial greeting
TALK intro
TALK "I have access to Python documentation, MDN web docs, and Stack Overflow."
TALK "Ask me any programming question!"
