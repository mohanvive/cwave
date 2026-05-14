import ballerina/ai;
import ballerina/mcp;
import ballerinax/googleapis.calendar;

final ai:Agent cwaveAgent = check new (
    systemPrompt = {
        role: string `HR Agent`,
        instructions: string `You are an HR assistant for CWave. Your role is to help employees with human resources questions and support.

**Scope:**

* Answer only questions related to HR topics: benefits, payroll, leave policies, hiring, onboarding, workplace conduct, performance management, compensation, and similar HR matters.
* Refer only to CWave's HR knowledge base and policies. Do not provide general HR advice or information from external sources.
* If a question falls outside HR or is not covered in your knowledge base, politely decline and suggest the employee contact the HR department directly.

**Behavior:**

* Be professional and courteous in all interactions.
* Keep responses clear and concise.
* If you're unsure about a policy or don't have the information, say so rather than guessing.
* Do not discuss topics unrelated to HR (technical support, business strategy, product questions, etc.).

**Tools:**

* Use getEventsTool to retrieve HR calendar events when employees ask about upcoming HR-related events, deadlines, training sessions, or company-wide HR activities.

**When uncertain:**

* If a question is borderline HR-related but you lack specific information, acknowledge the HR relevance but direct the employee to HR for accurate details.
* Never invent or assume company policies.`
    }, memory = aiShorttermmemory, model = openaiModelprovider, tools = [retrievePolicies, getEventsTool, aiMcpbasetoolkit]
);

@ai:AgentTool
isolated function retrievePolicies(string query) returns string|error {
    ai:QueryMatch[] aiQuerymatch = check aiVectorknowledgebase.retrieve(string `${query}`);
    return aiQuerymatch.toString();
}

# Gets events. 
# + return - Type of the variable 
@ai:AgentTool
@display {label: "", iconPath: "https://bcentral-packageicons.azureedge.net/images/ballerinax_googleapis.calendar_3.2.1.png"}
isolated function getEventsTool() returns stream<calendar:Event, error?>|error {
    stream<calendar:Event, error?> streamCalendarEventError = check calendarClient->getEvents(calendarId);
    return streamCalendarEventError;
}

final ai:ShortTermMemory aiShorttermmemory = check new ();

isolated class AiMcpbasetoolkit {
    *ai:McpBaseToolKit;
    private final mcp:StreamableHttpClient mcpClient;
    private final readonly & ai:ToolConfig[] tools;

    public isolated function init(string serverUrl, mcp:Implementation info = {name: "MCP", version: "1.0.0"},
            *mcp:StreamableHttpClientTransportConfig config) returns ai:Error? {
        final map<ai:FunctionTool> permittedTools = {
            "getLeaveBalance": self.getleavebalance,
            "getLeaveHistory": self.getleavehistory,
            "applyLeave": self.applyleave,
            "updateLeaveStatus": self.updateleavestatus,
            "listEmployees": self.listemployees
        };

        do {
            self.mcpClient = check new mcp:StreamableHttpClient(serverUrl, config);
            self.tools = check ai:getPermittedMcpToolConfigs(self.mcpClient, info, permittedTools).cloneReadOnly();
        } on fail error e {
            return error ai:Error("Failed to initialize MCP toolkit", e);
        }
    }

    public isolated function getTools() returns ai:ToolConfig[] => self.tools;

    @ai:AgentTool
    public isolated function getleavebalance(mcp:CallToolParams params) returns mcp:CallToolResult|error {
        return self.mcpClient->callTool(params);
    }

    @ai:AgentTool
    public isolated function getleavehistory(mcp:CallToolParams params) returns mcp:CallToolResult|error {
        return self.mcpClient->callTool(params);
    }

    @ai:AgentTool
    public isolated function applyleave(mcp:CallToolParams params) returns mcp:CallToolResult|error {
        return self.mcpClient->callTool(params);
    }

    @ai:AgentTool
    public isolated function updateleavestatus(mcp:CallToolParams params) returns mcp:CallToolResult|error {
        return self.mcpClient->callTool(params);
    }

    @ai:AgentTool
    public isolated function listemployees(mcp:CallToolParams params) returns mcp:CallToolResult|error {
        return self.mcpClient->callTool(params);
    }
}
