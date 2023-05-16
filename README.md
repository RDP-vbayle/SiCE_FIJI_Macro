

#  Welcome to SiCE_FIJI_Macro repository!

Hi! You will find here macros for FIJI developped in the [SiCE Team](http://www.ens-lyon.fr/RDP/SiCE/Home.html). As there is not website to directly install and update directly from FIJI you will have to download .ijm files and add them to the corresponding directories in your Fiji/ImageJ installation, or simply drag and drop on FIJI toolbar.

![](http://www.ens-lyon.fr/RDP/local/cache-vignettes/L130xH130/siteon0-1ee2f.jpg?1680013421) ![](http://www.ens-lyon.fr/RDP/SiCE/Home_Fr_files/Sans%20titre%20-%201_1.png)![](assets/images/sice_logo.png)
## Quick links
- [SiCE SpotDetector](#SpotDetector )
- [SiCE FRAPanalyser](#FRAPanalyser)
- [SiCE RootGravi](#RootGravi)
- [SiCE ToolBox](#ToolBox)
-  [SiCE FastRed](#FastRed)
- [SeedDev_Curvature](#Curvature)
- [SeedDev_Immuno](#Immuno)
- [SeedDev_Nuclei](#Nuclei)

## Macros

 ### SpotDetector 
 As described in [Bayle et al.2017](https://bio-protocol.org/pdf/bio-protocol2145.pdf), this macro allows automatic counting of the number of intracellular compartments in Arabidopsis root cells, which can be used for example to study endocytosis
or secretory trafficking pathways and to compare membrane organization between different genotypes
or treatments. While developed for Arabidopsis roots, this method can be used on other tissues, cell
types and plant species.  
![SiCE SpotDetector](SpotDetector)
 
### FRAPanalyser
![SiCE FRAPanalyser](FRAPanalyser)
### RootGravi
[SiCE RootGravi](RootGravi)
### ToolBox
[SiCE ToolBox](ToolBox)
### FastRed
This Fiji macro helps analysis Arabidopsis T-DNA transformed segregation with the [fast red selection](https://pubmed.ncbi.nlm.nih.gov/19891705/).The technology is based on the expression of a fluorescent co-dominant screenable marker FAST, under the control of a seed-specific promoter.The FAST marker harbors a fusion gene encoding either GFP or RFP with an oil body membrane protein that is prominent in seeds.

 - Macro INPUT: Folder containing Brightfield images of the seeds, name of the line ended by "_bf" and the corresponding fluo image (example: 1903-1-01_bf and 1903-1-01 pictures).
  ![](assets/images/FastRedFiles.png)
 - Macro OUTPUT: Table containing Pictures names, number of seeds segmented, number of fluorescent seeds and corresponding ratio and Segregation as following:  
 
**Expected segregation ratio from self-ferilized T1s:**  
 Single insertion: 75% Fluorescent & 25% Black seeds  
 Two insertions: 94%  Fluorescent & 6% Black seeds  
 Three  insertions: 94%  Fluorescent & 6% Black seeds  
 Single insertion Embryo lethal: 66% Fluorescent & 33% Black seeds  
 Single insertion Gametophyte lethal: 50% Fluorescent & 50% Black seeds  
 ![](assets/images/FastRedTable.png)  
[SiCE FastRed](FastRed)
 ### SeedDev_Curvature
![SeedDev_Curvature](Curvature)
### SeedDev_Immuno
- ![SeedDev_Immuno](Immuno)
### SeedDev_Nuclei
- ![SeedDev_Nuclei](Nuclei)
###  
- Misc...








