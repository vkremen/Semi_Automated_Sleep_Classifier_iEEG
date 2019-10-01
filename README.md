# Semi_Automated_Sleep_Classifier

Semi-automated assesment of sleep based on feature analysis of EEG. 

Runs feature extraction and displays attributes of the time-domain data and launches UI for expert to enable to classify 30-second epochs of the data into AASM2012 sleep classes. 

If all data are ready in structure described for subject_id_data.mat, then only Assess_the_sleep script can be run to score one patients. Otherwise processing of multiple patients can be done using UW_sleep_wrapper.m or its modification in case of other input formats. Assess_the_sleep script can be also called in loop to speed up processing. 

# To generate a full Help Report, in the Current Folder browser, 
 navigate to the folder you want to check, click , and then select Reports > Help Report. 
 The Help Report displays in the MATLAB web browser.

# Version 1.0, 2019, Vaclav Kremen, Mayo Clinic.

# Copyright (c) 2019, Mayo Foundation for Medical Education and Research (MFMER), 
 All rights reserved. Academic, non-commercial use of this software is allowed with 
 expressed permission of the developers. MFMER and the developers disclaim all implied 
 warranties of merchantability and fitness for a particular purpose with respect to this software, 
 its application, and any verbal or written statements regarding its use. 
 The software may not be distributed to third parties without consent of MFMER. 
 Use of this software constitutes acceptance of these terms and acceptance of all risk 
 and liability arising from the software's use.

# Contributors: Vaclav Kremen, Vaclav Gerla.

# Acknowledgment: When use whole, parts, or are inspired by, we appreciate 
 you acknowledge and refer these journal papers:
 Kremen, V., Duque, J. J., Brinkmann, B. H., Berry, B. M., Kucewicz, M. T., 
 Khadjevand, F., G.A. Worrell, G. A. (2017). Behavioral state classification in 
 epileptic brain using intracranial electrophysiology. Journal of Neural 
 Engineering, 14(2), 026001. https://doi.org/10.1088/1741-2552/aa5688

 Kremen, V., Brinkmann, B. H., Van Gompel, J. J., Stead, S. (Matt) M.,
 St Louis, E. K., & Worrell, G. A. (2018). Automated Unsupervised Behavioral
 State Classification using Intracranial Electrophysiology. 
 Journal of Neural Engineering. https://doi.org/10.1088/1741-2552/aae5ab

 Gerla, V., Kremen, V., Macas, M., Dudysova, D., Mladek, A., Sos, P., & Lhotska, L. (2019). 
 Iterative expert-in-the-loop classification of sleep PSG recordings using a 
 hierarchical clustering. Journal of Neuroscience Methods, 317(February), 
 61?70. https://doi.org/10.1016/j.jneumeth.2019.01.013
