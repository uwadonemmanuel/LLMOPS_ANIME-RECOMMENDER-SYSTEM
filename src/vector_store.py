from langchain_text_splitters import CharacterTextSplitter
from langchain_chroma import Chroma
from langchain_community.document_loaders.csv_loader import CSVLoader
from langchain_huggingface import HuggingFaceEmbeddings

from dotenv import load_dotenv
load_dotenv()

class VectorStoreBuilder:
    def __init__(self,csv_path:str,persist_dir:str="chroma_db"):
        self.csv_path = csv_path
        self.persist_dir = persist_dir
        self.embedding = HuggingFaceEmbeddings(model_name = "all-MiniLM-L6-v2")
    
    def download_model(self):
        """
        Pre-download the embedding model so it's ready to use.
        This method downloads the model from HuggingFace Hub if not already cached.
        The model downloads automatically on first use, but this pre-downloads it.
        
        Note: The model will be cached locally and reused in future runs.
        """
        print("Pre-downloading embedding model: all-MiniLM-L6-v2...")
        print("This may take a few minutes on first run. The model will be cached for future use.")
        print("=" * 60)
        
        # Trigger model download by embedding a dummy text
        # This will download and cache the model
        try:
            print("[1/2] Initializing model (downloading if needed)...")
            dummy_text = "Downloading model..."
            result = self.embedding.embed_query(dummy_text)
            
            if result and len(result) > 0:
                print("[2/2] Model loaded into memory")
                print("=" * 60)
                print("✓ Model downloaded and ready to use!")
                print(f"✓ Embedding dimension: {len(result)}")
                print("✓ Model is cached and will be reused in future runs.")
            else:
                print("⚠️  Model loaded but embedding test returned empty result")
                
        except Exception as e:
            print("=" * 60)
            print(f"⚠️  Error downloading model: {e}")
            print("The model will be downloaded automatically when first used.")
            print("You can also run: python3 download_embedding_model.py")
            raise
    
    def build_and_save_vectorstore(self):
        loader = CSVLoader(
            file_path=self.csv_path,
            encoding='utf-8',
            metadata_columns=[]
        )

        data = loader.load()

        splitter = CharacterTextSplitter(chunk_size=1000,chunk_overlap=0)
        texts = splitter.split_documents(data)

        # Chroma 0.4.x automatically persists documents, no need to call persist()
        db = Chroma.from_documents(texts,self.embedding,persist_directory=self.persist_dir)

    def load_vector_store(self):
        return Chroma(persist_directory=self.persist_dir,embedding_function=self.embedding)



