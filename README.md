### Problem Definition
A company needs to search for information and navigate through a large amount of documentation. This documentation has the property of being frequently updated, but also storing old and not widely known information about the company and its products. When looking after some piece of information, new employees rely on the help of older members of the company, which in turn have their workflow interrupted.

How to improve the process of finding information while empowering users to do such a process on their own?

### Quick Overview of the Proposed Solution
Develop a Retrieval-Augmented Generation (RAG) application to endow the users with the ability to query the documentation and, at the same time, also have directions of resources for further reading.

The RAG approach consists of building a Vector-Based Database leveraged by the embeddings from powerful pre-existing models, and then retrieving the pieces of information that present a higher similarity with the queried question. With such information at hand, we present everything together (query + retrieved documents) to a powerful Large Language Model (LLM), and let it synthesize a consistent response to what was asked.

### AWS Documentation
The problem stated that part of the documentation used in the problem we were meant to solve was the AWS Documentation, which is publicly available. In a quick search, I did not find any way of downloading the entire documentation other than through Web Scrapping. However, I found a GitHub Repository (from three years ago) with all AWS documentation available at the time.

Considering we are developing a solution for a customer, I thought it would be reasonable to assume the documents were already available to me and, instead of focusing on developing a Web Scrapper, I simply downloaded the outdated documentation and performed a quick rearrangement on the repositories with a [Shell Script](rearrange_files.sh).

### Pre-Processing Documentation
In regular documentation, there may (and probably will) be different file formats. Here we had no different scenario. Throughout this documentation, I found different file formats, from programming language files (`.cpp`, `.java`, etc), to `.rst` and `.md`. However, for simplicity's sake, I decided to keep only those documentation composed by `.md` files. Otherwise, I would be required to develop many context-specific treatments that I believe are only worthy of developing in a Non-POC format.

Further, due to time restrictions and computation costs, I decided to build a "toy documentation" comprising only a small fraction of the original dataset.

The resulting dataset was entirely written as `.md` files. As is common, most of the documentation was structured and displayed following a content index that assembled all the pieces into one concise text. Consequently, there are two ways of thinking about the documentation:

- A composition where we can follow hyperlinks and navigate through the documents in a pre-established order;
- A self-contained text that does not need to be considered within a context to make sense.

Taking the two views mentioned above, I built two different datasets for further analysis. The [first one](transform-docs-into-aggregated-files.ipynb) builds a larger document replacing references of content by the content itself. The [second one](transform-docs-to-plain-text.ipynb) simply converts the `.md` files into `.txt` preserving their original display.

### Technical View of the Solution
The solution develops a composition of models with the aid of the [LangChain Framework](https://www.langchain.com/).

As mentioned above, an RAG approach uses a Vector-Based Database to leverage the process of finding relevant documents to be used as context to answer queries. Naturally, the first step we need to think of is which database to use. I decided to use [ChromaDB](https://www.trychroma.com/) as it easily integrates with the remaining packages I use throughout this project.

Since ChromaDB requires an embedding model to represent the pieces of text that will later be retrieved, I also need to define an embedding model. Despite HuggingFace having an [extensive benchmark](https://huggingface.co/spaces/mteb/leaderboard) on free and private embedding models, I decided to keep it simple and go with the default embedding model from OpenAI (`text-embedding-ada-002` the 80th position in the mentioned benchmark).

After retrieving the relevant documents, we need to present them to the language model responsible for drawing a concise response. Once again, HuggingFace presents a leaderboard with [the best open-source LLMs](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard). However, I decided to simply use OpenAI's default LLM (`gpt-3.5-turbo-instruct`).

#### Why to go with the default OpenAI models?
Considering this is a Proof-of-Concept project, I believe there is no need to overthink a solution that might after serve as a baseline for later improvements. Besides that, with GPT3.5 we have the benefit of having a considerably large model with some problems softened, e.g. the model does not suffer heavily Out-Of-Vocabulary terms due to subword tokenization.

### Experiments
Since we are developing a POC project, I see no need to experiment for the best LLM or the best Embedding model. However, with the ones we have chosen, we still need to define the best chunking strategy and find the more consistent model.

#### Chunking
Why does chunking matter? The size of the chunks is strictly bonded to whether or not the retrieved documents will present enough context to generate a consistent/relevant answer. This can easily be visualized in the following example:

Suppose we are queried the sentence `How Old Are The Pyramids?`, and the context documents have a relevant piece of content to that matter, let's say `[...] the ancient Egyptian pyramids were built between about roughly 2700 B.C. and 1500 B.C.[...]`. If we chunk the content into 70 characters-long sentences, we would end up with something like `the ancient Egyptian pyramids were built between about roughly 2700` and `B.C. and 1500 B.C.[...]`, which are not necessarily wrong, but is a least incomplete and misleading.

Hence, independently of the chosen model, it is almost always interesting to find the best context window (or chunk size). Here, we experiment with three alternatives:

- Merging documents according to index order:
    - Chunk Size: 1024
    - Chunk Size: 2048
- Keeping original documents:
    - Chunk Size: 2048

### Results
Considering that our problem requires a model capable of generating not only semantically correct content but also capable of best grasping the gist of the question and extracting the fittest pieces of information, I evaluated the resulting models according to three metrics:

- Faithfulness: What proportion of the claims are correct matches (answer/context), when compared to the number of total claims? The closer to 1, the better.
- Answer Relevancy: Asks the model to generate N questions relative to the generated answer. Posteriorly we calculate the average cosine similarity between the generated answer and the "artificial questions". The closer to 1, the better.
- Semantic Quality: Manual validation to rank the responses according to their fitness to the ground truth. The higher the better.

The third metric is a more qualitative one and is meant to disambiguate possible errors in the quantitative metrics.

To validate the quality of the models, I presented each of them with questions with known ground truths. Then I listed the questions, the retrieved contexts, the models' answers, the ground truths, as well as the metrics and the best model for each question. In the end, the model which presents the more dominant performance over the rest was chosen to be used in the final solution. All the experimental results are available in [This Google Sheets](https://docs.google.com/spreadsheets/d/1QxzumcfxOG4qO22HyfJ-hGm9PrV2uZLC6gviTM_LF6E/edit?usp=sharing).


### Final Model
The best-performing model, according to the validation above, was the one that received context chunked based on the the self-contained assumption.


### Observations and Further Improvements:
- Using OpenAI models might cause the project to have fixed costs other than those related to infrastrucutre. A possible workaround would be to use Open-Source models, like those listed by Hugging Face;
- The project has some restrictions with regard to the data, i.e. the data cannot leave US and cannot be accessed externally. Such restrictions could easily be dealt with by using a Cloud Platform such as AWS. In AWS, we can define access permissions to data and computing instances such as EC2 machines. Besides that, we can also restrict the data to be processed only inside a geographic region with the aid of Local Zones.
- The solution proposed here can easily be deployed to AWS in a SageMaker endpoint, or through an EC2 instance with a dockerized application.
