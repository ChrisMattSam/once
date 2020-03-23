Author: Christopher Sampah
Email: christopher.m.sampah@gmail.com

Date: 7/1/2019
Script: filter_publications

Having a received a query of all organizational publications from the last 20 years, the goal is to only select those that pertain to personnel-related topics,
such as: retirement, healthcare, recruitment, readiness, training, force structure, veterans, and work climate.  The final deliverable was to be two tables,
one for draft-Final publications, the other for Final publications, each table broken up by topic, with the values:
Title, Date, Publication Number, Abstract, Authors, Organizational Points of Contact (must be a current employee), Status (of the publication).

Date: 7/31/2019
Scripts: generate_synth_data, generation_fxns

The objective is to generate a synthetic population from a non-disclosable dataset primarily using R's synthpop package after formatting the dataset and encoding one feature.
Leaned heavily on R's synthpop package (see: https://cran.r-project.org/web/packages/synthpop/vignettes/synthpop.pdf) with some modifications.

Date: 3/23/2020
Scripts: directory_compare/

The objective of this file is to compare files between any two directories dir_A and dir_B, returning a .json of files that have been added to dir_A and not dir_B ('added'),
added to dir_B but not dir_A ('deleted'), or have been modified in dir_A and not dir_B ('modified'). 