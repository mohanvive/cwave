# CWave — AI-Powered HR Agent
 
CWave is an intelligent HR assistant built with [Ballerina](https://ballerina.io/). It uses a large language model (GPT-4o) to answer employee questions about HR policies, retrieve calendar events, and manage leave requests — all through a conversational chat interface.
 
The project is structured as a Ballerina workspace containing two packages:
 
| Package | Description |
|---|---|
| `cwave` | The main AI HR agent — exposes a chat HTTP endpoint |
| `cwave_mcp_leave_service` | An MCP (Model Context Protocol) server that manages employee leave data |
 
---
 
## Architecture Overview
 
```
Employee
   │
   │  POST /cwaveagent/chat
   ▼
┌─────────────────────────────────────────────────┐
│              CWave AI Agent (GPT-4o)             │
│                                                  │
│  ┌────────────────┐  ┌────────────────────────┐  │
│  │ Policy Retrieval│  │  Google Calendar Tool  │  │
│  │ (Pinecone RAG) │  │  (HR events/deadlines) │  │
│  └────────────────┘  └────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │        MCP Leave Management Tools        │    │
│  │  getLeaveBalance · getLeaveHistory       │    │
│  │  applyLeave · updateLeaveStatus          │    │
│  │  listEmployees                           │    │
│  └──────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
                        │
                        ▼
         ┌──────────────────────────┐
         │  cwave_mcp_leave_service │
         │  MCP server on :8080     │
         └──────────────────────────┘
```
 
The agent uses **Retrieval-Augmented Generation (RAG)** via a Pinecone vector knowledge base to answer questions grounded in CWave's HR policies. It also connects to **Google Calendar** for HR event lookups and delegates all leave management operations to the MCP leave service.
 
---
 
## Features
 
- **Conversational HR assistant** — employees chat with the agent over HTTP
- **Policy Q&A** — answers are grounded in CWave's HR knowledge base (stored in Pinecone)
- **Calendar integration** — retrieves upcoming HR events, deadlines, and training sessions from Google Calendar
- **Leave management via MCP** — employees can check balances, apply for leave, and view history; HR can approve or reject requests
- **Short-term memory** — the agent maintains conversation context within a session
- **LLM-based evaluation** — automated evals use a judge LLM to verify agent response quality
---
 
## Project Structure
 
```
cwave/
├── Ballerina.toml                      # Workspace definition
├── cwave/                              # Main AI agent package
│   ├── Ballerina.toml
│   ├── main.bal                        # HTTP listener + chat endpoint
│   ├── agents.bal                      # Agent definition, tools, MCP toolkit
│   ├── connections.bal                 # OpenAI, Pinecone, Calendar clients
│   ├── config.bal                      # Configurable secrets
│   ├── types.bal                       # Type definitions
│   ├── functions.bal                   # Utility functions
│   ├── data_mappings.bal               # Data mapping logic
│   └── tests/
│       ├── tests.bal                   # LLM-judged evaluation tests
│       └── resources/evalsets/
│           └── data-retrieval.evalset.json
└── cwave_mcp_leave_service/            # MCP leave management server
    ├── Ballerina.toml
    ├── main.bal                        # MCP service + all leave tools
    ├── agents.bal
    ├── connections.bal
    ├── config.bal
    ├── types.bal
    ├── functions.bal
    └── data_mappings.bal
```
 
---
 
## Prerequisites
 
- [Ballerina](https://ballerina.io/downloads/) `2201.13.4` (Swan Lake Update 13)
- An **OpenAI** API key (GPT-4o and `text-embedding-3-large` are used)
- A **Pinecone** index pre-populated with CWave's HR policy documents
- A **Google Calendar** OAuth2 credentials (for the HR events tool)
---
 
## Configuration
 
Both packages use Ballerina's configurable values. Create a `Config.toml` file in each package directory (or at the workspace root) with the following:
 
### `cwave/Config.toml`
 
```toml
openai_key     = "<your-openai-api-key>"
pinecone_key   = "<your-pinecone-api-key>"
calendarId     = "<your-google-calendar-id>"
refreshUrl     = "https://oauth2.googleapis.com/token"
refreshToken   = "<your-google-oauth-refresh-token>"
clientId       = "<your-google-oauth-client-id>"
clientSecret   = "<your-google-oauth-client-secret>"
```
 
> The MCP leave service URL is hardcoded to `http://localhost:8080/mcp` in `connections.bal`. Update this if your leave service runs elsewhere.
 
---
 
## Running the Application
 
### 1. Start the MCP Leave Service
 
```bash
cd cwave_mcp_leave_service
bal run
```
 
This starts the leave management MCP server on port `8080`.
 
### 2. Start the HR Agent
 
```bash
cd cwave
bal run
```
 
This starts the chat agent HTTP service. By default it listens on Ballerina's default HTTP port (`9090`).
 
---
 
## API
 
### Chat with the Agent
 
**`POST /cwaveagent/chat`**
 
```json
{
  "message": "What is CWave's annual leave policy?",
  "sessionId": "user-session-123"
}
```
 
**Response:**
 
```json
{
  "message": "According to CWave's HR policy, employees are entitled to..."
}
```
 
The `sessionId` field is used to maintain conversation history across turns within the same session.
 
---
 
## MCP Leave Management Tools
 
The `cwave_mcp_leave_service` exposes the following tools to the agent via the Model Context Protocol:
 
| Tool | Description |
|---|---|
| `getLeaveBalance` | Returns annual, sick, and casual leave balances for an employee |
| `applyLeave` | Submits a leave request (type: annual / sick / casual) |
| `updateLeaveStatus` | Approves or rejects a pending leave request |
| `getLeaveHistory` | Retrieves the full leave request history for an employee |
| `listEmployees` | Lists all employees registered in the system |
 
> **Note:** The current in-memory data store is pre-seeded with three employees: **James**, **John**, and **Jinger**. Data is reset when the service restarts.
 
---
 
## Running Evaluations
 
The `cwave` package includes LLM-judged evaluations using Ballerina's `ai:` test framework:
 
```bash
cd cwave
bal test --groups evaluations
```
 
Tests are driven by conversation threads defined in `tests/resources/evalsets/data-retrieval.evalset.json`. Each test runs **5 times** and requires a **minimum 80% pass rate**. A GPT-4o judge determines whether the agent's actual response is semantically equivalent to the expected response.
 
---
 
## Agent Behaviour & Scope
 
The HR agent is intentionally scoped to HR topics only:
 
- ✅ Benefits, payroll, leave policies, onboarding, performance management, workplace conduct
- ✅ Upcoming HR events and deadlines (via Google Calendar)
- ✅ Leave balance checks and applications (via MCP)
- ❌ Technical support, business strategy, or product questions — the agent will politely decline and direct the employee to HR
---
 
## License
 
This project does not currently include a license file. Please contact the repository owner for usage terms.