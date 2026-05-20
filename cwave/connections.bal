import ballerina/ai;
import ballerinax/ai.openai;
import ballerinax/ai.pinecone;
import ballerinax/googleapis.calendar;

final openai:ModelProvider openaiModelprovider = check new (string `${openai_key}`, "gpt-4o");
final pinecone:VectorStore pineconeVectorstore = check new ("https://cwave-collection-2osj67z.svc.aped-4627-b74a.pinecone.io", string `${pinecone_key}`);
final openai:EmbeddingProvider openaiEmbeddingprovider = check new (string `${openai_key}`, "text-embedding-3-large");
final ai:VectorKnowledgeBase aiVectorknowledgebase = new (pineconeVectorstore, openaiEmbeddingprovider, ai:AUTO);
final calendar:Client calendarClient = check new ({
    auth: {
        refreshUrl: refreshUrl,
        refreshToken: refreshToken,
        clientId: clientId,
        clientSecret: clientSecret
    }
});
final AiMcpbasetoolkit aiMcpbasetoolkit = check new (string `${mcpUrl}`);
