#!/bin/bash
# setup_onko_neoepitope_pipe.sh
# 初始化 Onko_Neoepitope_Pipe 管线结构

set -e

# ==========================================
# 配置变量
# ==========================================
AUTHOR="@jingyu"  # 替换为你的 GitHub 用户名

# ==========================================
# 1. Install the official NF-CORE modules
# ==========================================
echo ">>> Step 1: Installing nf-core modules..."

NFCORE_MODULES=(
    # ---------- Phase 1: QC & Mapping / Alignment ----------
    "fastqc"
    "trimgalore"
    "fastp"
    "sortmerna"
    "bbmap/bbsplit"
    "bwamem2/index"
    "bwamem2/mem"
    "star/genomegenerate"
    "star/align"
    # ---------- Phase 2: BAM processing & Variant discovery ----------
    "samtools/sort"
    "samtools/merge"
    "samtools/index"
    "gatk4/markduplicates"
    "gatk4/baserecalibrator"
    "gatk4/applybqsr"
    "gatk4/getpileupsummaries"
    "gatk4/calculatecontamination"
    "gatk4/mutect2"
    "gatk4/learnreadorientationmodel"
    "gatk4/filtermutectcalls"
    "deepsomatic"
    "manta/somatic"
    "manta/tumoronly"
    "manta/germline"
    "cnvkit/reference"
    "cnvkit/batch"
    # ---------- Phase 3: Molecular Characterization ----------
    "ensemblvep/download"
    "ensemblvep/vep"
    "arriba/arriba"
    "subread/featurecounts"
    "optitype"
    "hlala/typing"
    # ---------- Phase 6: Report ----------
    "multiqc"
)

for mod in "${NFCORE_MODULES[@]}"; do
    echo "Installing $mod..."
    nf-core modules install "$mod" --force || echo "Warning: Failed to install $mod"
done

# ==========================================
# 2. Create LOCAL MODULES
# ==========================================
echo ">>> Step 2: Creating Local Custom Modules..."

# ---------- Phase 3: Molecular Characterization ----------
echo "Creating Phase 3 modules..."

yes n | nf-core modules create tpmexpcal \
    --author $AUTHOR --label process_single --meta --force
#    --conda-name subread --conda-package-version 3.14.1 \
    # --force

yes n | nf-core modules create kourami \
    --author $AUTHOR --label process_medium --meta --force
#    --conda-name kourami --conda-package-version 0.9.6 \
    

nf-core modules create arcashla \
    --author $AUTHOR --label process_medium --meta \
    --conda-name arcas-hla --conda-package-version 0.6.0 \
    --force

# hlahd - 无 bioconda 包，需手动安装
yes n | nf-core modules create hlahd \
    --author $AUTHOR --label process_high --meta --force

# ---------- Phase 4: Neoepitope Generation ----------
echo "Creating Phase 4 modules..."

yes n | nf-core modules create peptidegenerator \
    --author $AUTHOR --label process_low --meta --force

# MHC Binding Prediction - Core Tools
# netmhcpan/netmhciipan - 需要学术许可证，无公开 conda 包
yes n | nf-core modules create netmhcpan \
    --author $AUTHOR --label process_medium --meta --force

yes n | nf-core modules create netmhciipan \
    --author $AUTHOR --label process_medium --meta --force

nf-core modules create mhcflurry \
    --author $AUTHOR --label process_medium --meta \
    --conda-name mhcflurry --conda-package-version 2.1.5 \
    --force

nf-core modules create mhcnuggets \
    --author $AUTHOR --label process_medium --meta \
    --conda-name mhcnuggets --conda-package-version 2.4.1 \
    --force

# epytope (formerly FRED2)
nf-core modules create epytope \
    --author $AUTHOR --label process_medium --meta \
    --conda-name epytope --conda-package-version 3.3.1 \
    --force

yes n | nf-core modules create neosv \
    --author $AUTHOR --label process_medium --meta --force

# pVACtools Suite (Nested structure)
echo "Creating pVACtools modules..."
mkdir -p modules/local/pvactools

yes n | nf-core modules create pvactools/pvacseq \
    --author $AUTHOR --label process_high --meta --force
#    --conda-name python --conda-package-version 3.14.1 \
    

yes n | nf-core modules create pvactools/pvacfuse \
    --author $AUTHOR --label process_medium --meta --force
#    --conda-name python --conda-package-version 3.14.1 \
    

yes n | nf-core modules create pvactools/pvacbind \
    --author $AUTHOR --label process_medium --meta --force
#    --conda-name python --conda-package-version 3.14.1 \
    

# ---------- Phase 5: Prioritization ----------
echo "Creating Phase 5 modules..."

# lohhla - 复杂依赖，通常用 Docker/Singularity
nf-core modules create lohhla \
    --author $AUTHOR --label process_high --meta \
   --conda-name lohhla --conda-package-version 20171108 \
    --force

yes n | nf-core modules create finaltablegenerator \
    --author $AUTHOR --label process_single --meta --force
#   --conda-name python --conda-package-version 3.14.1 \
    

yes n | nf-core modules create filterranker \
    --author $AUTHOR --label process_low --meta --force
#    --conda-name python --conda-package-version 3.14.1 \


# ---------- Phase 6: Clinical Delivery ----------
echo "Creating Phase 6 modules..."

yes n | nf-core modules create summary_report \
    --author $AUTHOR --label process_single --meta --force
#    --conda-name pandas --conda-package-version 3.14.1 \
    

# ==========================================
# 3. Create SUBWORKFLOWS (Phase level)
# ==========================================
echo ">>> Step 3: Creating Subworkflows..."

SUBWORKFLOWS=(
    "input_check"
    "phase1_qc_alignment"
    "phase2_variant_discovery"
    "phase3_molecular_char"
    "phase4_neoepitope_gen"
    "phase5_prioritization"
    "phase6_clinical_delivery"
)

for sw in "${SUBWORKFLOWS[@]}"; do
    echo "Creating subworkflow: $sw"
    nf-core subworkflows create "$sw" --author $AUTHOR --force
done

# ==========================================
# 4. Create Internal Sub-steps files
# ==========================================
echo ">>> Step 4: Creating Internal Sub-step files..."

# Phase 1
touch subworkflows/local/phase1_qc_alignment/qc.nf
touch subworkflows/local/phase1_qc_alignment/dna_alignment.nf
touch subworkflows/local/phase1_qc_alignment/rna_alignment.nf

# Phase 2
touch subworkflows/local/phase2_variant_discovery/bam_preprocessing.nf
touch subworkflows/local/phase2_variant_discovery/snv_indel_calling.nf
touch subworkflows/local/phase2_variant_discovery/sv_calling.nf
touch subworkflows/local/phase2_variant_discovery/cnv_calling.nf

# Phase 3
touch subworkflows/local/phase3_molecular_char/variant_annotation.nf
touch subworkflows/local/phase3_molecular_char/rna_analysis.nf
touch subworkflows/local/phase3_molecular_char/hla_typing.nf

# Phase 4
touch subworkflows/local/phase4_neoepitope_gen/peptide_generation.nf
touch subworkflows/local/phase4_neoepitope_gen/mhc_prediction.nf

# Phase 5
touch subworkflows/local/phase5_prioritization/feature_integration.nf
touch subworkflows/local/phase5_prioritization/epitope_prioritization.nf

# Phase 6
touch subworkflows/local/phase6_clinical_delivery/reporting.nf

# ==========================================
# 5. Summary
# ==========================================
echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Local modules created:"
ls -d modules/local/*/ 2>/dev/null | wc -l | xargs echo "  Count:"
echo ""
echo "Subworkflows created:"
ls -d subworkflows/local/*/ 2>/dev/null | wc -l | xargs echo "  Count:"
echo ""
echo "Next steps:"
echo "  1. nf-core lint"
echo "  2. Fill module main.nf files"
echo "  3. Fill subworkflow files"

