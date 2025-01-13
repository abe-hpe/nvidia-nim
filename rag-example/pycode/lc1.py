from langchain_nvidia_ai_endpoints import ChatNVIDIA

# connect to a LLM NIM running at llmhost:8000, specifying a specific model
llm = ChatNVIDIA(base_url="http://llmhost:8000/v1", model="meta/llama3-8b-instruct")

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_messages([
    ("system", (
        "You are a rude and abrupt AI!"
        "Your responses should be concise, insulting, and no longer than two sentences."
        "Say you don't know if you don't have this information."
    )),
    ("user", "{question}")
])

chain = prompt | llm | StrOutputParser()

print(chain.invoke({"question": "What's the difference between a GPU and a CPU?"}))
print(chain.invoke({"question": "What does the A in the NVIDIA A100 stand for?"}))
print(chain.invoke({"question": "How much memory does the NVIDIA H200 have?"}))

from langchain_nvidia_ai_endpoints import NVIDIAEmbeddings

# Initialize and connect to a NeMo Retriever Text Embedding NIM (nvidia/nv-embedqa-e5-v5) running at localhost:8000
embedding_model = NVIDIAEmbeddings(model="nvidia/nv-embedqa-e5-v5",
                                   base_url="http://embeddinghost:8000/v1")

# Create vector embeddings of the query
myvec=embedding_model.embed_query("How much memory does the NVIDIA H200 have?")[:10]
print(myvec)

from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader("https://nvdam.widen.net/content/udc6mzrk7a/original/hpc-datasheet-sc23-h200-datasheet-3002446.pdf")

document = loader.load()
print(document[0])

from langchain.text_splitter import RecursiveCharacterTextSplitter

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,
    chunk_overlap=100,
    separators=["\n\n", "\n", ".", ";", ",", " ", ""],
)

document_chunks = text_splitter.split_documents(document)
print("Number of chunks from the document:", len(document_chunks))

from langchain_community.vectorstores import FAISS

vector_store = FAISS.from_documents(document_chunks, embedding=embedding_model)
print(vector_store)

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_messages([
    ("system", 
        "You are a rude and abrupt AI!"
        "Your responses should be concise, insulting, and no longer than two sentences."
        "Do not hallucinate. Say you don't know if you don't have this information."
        # "Answer the question using only the context"
        "\n\nQuestion:{question}\n\nContext:{context}"
    ),
    ("user", "{question}")
])

chain = (
    {
        "context": vector_store.as_retriever(),
        "question": RunnablePassthrough()
    }
    | prompt
    | llm
    | StrOutputParser()
)

print(chain.invoke("How much memory does the NVIDIA H200 have?"))