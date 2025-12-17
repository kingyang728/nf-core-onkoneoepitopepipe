```mermaid
%%{init: {
 'theme': 'base',
 'themeVariables': {
   'fontSize': '20px',
   'fontFamily': 'arial'
 }
}}%%
flowchart TD
  %% --- 1. Define style ---
  classDef bigFont font-size:22px, padding:10px
  classDef inputFill fill:#e1f5fe,stroke:#01579b,stroke-width:2px,rx:5px,ry:5px
  classDef processFill fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,rx:5px,ry:5px
  classDef outputFill fill:#90EE90,stroke:#006400,stroke-width:2px,color:#000,font-weight:bold,rx:5px,ry:5px


  %% --- 2. Input Data Subgraph ---
  subgraph sub1["  Input Data & References  "]
     direction LR
     A[Raw FASTQ Files]:::inputFill
     B[Reference Genome<br/>FASTA]:::inputFill
     C[Gene Annotation<br/>GTF]:::inputFill
  end


  %% --- 3. QC & Cleaning Subgraphs ---
  subgraph sub2["**Quality Control**"]Open Preview to the Side
     direction TB
     D[FASTQC]:::processFill
     D --> E{Adapter Trimming}
     E -->|Option 1| F[TRIMGALORE]:::processFill
     E -->|Option 2| G[FASTP]:::processFill
     F --> H[Clean FASTQ]
     G --> H
  end


  subgraph sub3["**RNA QC &#40Optional&#41**"]
     direction TB
     I[BBSPLIT<br/>Remove Contaminants]:::processFill
     I --> J[SORTMERNA<br/>Remove rRNA]:::processFill
     J --> K[RNA-Clean FASTQ]
  end


  %% --- 4. Main Alignment "Super-Subgraph" ---
  subgraph sub4["  Phase 1.3: Parallel Alignment Workflows  "]
     direction LR
     subgraph sub4a["  DNA Alignment  "]
         direction TB
         L[BWAMEM2_INDEX]:::processFill
         M[BWAMEM2_MEM]:::processFill
         N[SAMTOOLS_SORT]:::processFill
         O[SAMTOOLS_MERGE<br/>&#40;If multi-lane&#41;]:::processFill
         B --> L
         L --> M
         H -- "Input for DNA" --> M
         M --> N --> O
     end


     subgraph sub4b["  RNA Alignment  "]
         direction TB
         P[STAR_GENOMEGENERATE]:::processFill
         Q[STAR_ALIGN]:::processFill
         R[SAMTOOLS_SORT]:::processFill
         B --> P
         C --> P
         P --> Q
         K -- "Input for RNA" --> Q
         Q --> R
     end
  end


  %% --- 5. Final Outputs ---
  subgraph sub5["  Final Outputs  "]
      direction LR
      S[Analysis-Ready<br/>DNA BAM]:::outputFill
      T[Analysis-Ready<br/>RNA BAM]:::outputFill
  end


  %% --- 6. Top-level Connections ---
  A --> D
  H --> I


  O --> S
  R --> T
 
  %% --- Apply Big Font Class ---
  class A,B,C,S,T bigFont
  ```
