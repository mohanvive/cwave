import ballerina/ai;
import ballerina/test;

isolated function loadEvalsetData() returns map<[ai:ConversationThread]>|error {
    return ai:loadConversationThreads("cwave/tests/resources/evalsets/data-retrieval.evalset.json");
}

@test:Config {
    groups: ["evaluations"],
    dataProvider: loadEvalsetData,
    dependsOn: [],
    runs: 5,
    minPassRate: 0.8
}
function dataRetrievalEval(ai:ConversationThread thread) returns error? {
    string expected = (check thread.traces[0].output).toString();
    string actual;
    string AgentResponse = check cwaveAgent.run(string `${thread.traces[0].userMessage.content.toString()}`);
    actual = AgentResponse;
    string result = check openaiModelprovider->generate(`You are an LLM Judge evaluating semantic similarity between an actual response and an expected response.

**Task:** Compare the two responses and determine if they are semantically similar in meaning, intent, and key information.

**Input:**

* Expected Response: ${expected}
* Actual Response: ${actual}

**Evaluation Criteria:**

* Do the responses convey the same core meaning?
* Are the key facts, concepts, or conclusions equivalent?
* Would a user understand them as saying essentially the same thing, even if worded differently?
* Minor differences in phrasing, tone, or style are acceptable if the substance is the same.

**Output Format:** Respond with ONLY one word:

* Correct — if the responses are semantically similar
* Incorrect — if they are not semantically similar

Do not include explanations, reasoning, or additional text.`);
    test:assertEquals(result, "Correct");

}
