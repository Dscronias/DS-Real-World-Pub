# Lab 3 - Shiny

Last lab, you worked on a dataset of emergency patients. This is the same dataset.

## Data description

Emergency services data, again. Similar dataset as the last lab. Each observation is the stay of one patient in one emergency service.

- It has already been (mostly) cleaned.
- All variables with missing values have had their missing values imputated (except severity, you won't need it)
- Patients with ages over 120yo have been removed
- Patients with length of stay over 4320 minutes have been removed

### Variables

- Region: geographical region where the service is located
- Service: name of the service
- id: unique identifier of the patient in the service
- severity: severity of the health status of the patient (= how bad it is). Scale of 1 to 5.
- Discharge mode: where the patient went when they exit the emergency service.
    - Home: patient was sent home.
    - Hospitalised: patient was hospitalised in the same hospital as the emergency service is located in.
    - Transferred to other hospital: patient was hospitalised in an hospital different from the one the emergency service is located in.
    - Died: patient died during the stay
- arrival_mode : how the patient arrived to the emergency service
    - Ambulance
    - Ambulance + firefighters
    - Ambulance + life support (ambulances with specialised equipment for more severe cases)
    - Cops
    - Helicopter
    - Personal (you went to the emergency service by yourself)
- los: length of stay. How long you've been in the service. In minutes.
- age: time between your date of birth and your date of arrival in the service. In years.
- Diagnostic: Main diagnostic of the patient.
- entry: date and hour of entry in the service
- exit: date and hour of exit in the service
- complexity: how complex the pathology of the patient is to treat, on a scale of 1 (lower) to 10 (higher). Complexity is calculated at the level of the diagnostic, not at the individual level (i.e. each diagnostic will have the same complexity level, even if for some patients, the same diagnostic may be more or less severe). It is a score (or latent variable) built from a PCA that includes, for each diagnostic:
    - The median length of stay
    - The percentage of entries with an ambulance (alone, or + firefighters, or + life support) or helicopter
    - The percentage of patients aged \<1 or \>75
    - The percentage of hospitalisations/transfers to other hospitals
    - The percentage of severity 3, 4 or 5.
- cost: total cost of the stay, in €.
- sas: "Service d'Accès aux Soins". When you have a medical emergency and your general practitioner ("médecin traitant") is not available, you are supposed to call "le 15". Initially, it was le SAMU (Service d'Aide Médicale Urgente). Now, it is the SAS. They will give you medical advice, and orient you towards some alternate offers: a teleconsultation, an emergency medical consultation in a dedicated healthcare centre ("centre de soins non-programmés"), an emergency service. For serious emergencies, an ambulance/helicopter is sent. In the context of the data, this variable indicates, for people that have come to the service by themselves (arrival_mode == "Personal"), if they called the SAS and were told to come ("yes"), if they did not call the SAS ("no") or if they called the SAS but were not told to go to an emergency service ("no").

## What you need to do:

- Currently, lauching the dashboard takes some time. Find a way to make it run faster.

Put the following in the dashboard:
- An introductory page where you explain what the data is about
  - Put a variable dictionary
  - Put an image, whatever you want (go on pexels.com)
- A table with all the data
  - Table must be downloadable
  - Must be filterable (according to the filters below)
- A few univariate and/or bivariate graphs
- A table that compares the odds ratios and risk ratios from the regression
- A dot-and-whisker plot of the risk ratios (estimate and 95% CI)
- One 3D graph with cost, length of stay and age (or relative_n_entries)

I want to be able to filter depending on these groups:

- Everybody
- People over 75
- People under 18
- All emergency services
- One or multiple emergency services
- All regions
- One region

Make it look good.

## Other possible content that comes to my mind

- Information about ALD patients vs. non-ALD
  - Age
  - Differences in costs
  - Severity/complexity
  - Length of stay
- About costs, by:
  - Age
  - Length of stay
  - Discharge mode

## Additional Shiny options I haven't talked about

### [Theming](https://rstudio.github.io/bslib/articles/theming/index.html)
There is a book about all this: [Outstanding User Interfaces with Shiny](https://unleash-shiny.rinterface.com/). Watch out though, the book was written in 2022, and some functions may have changed (it is the case with bslib, which is still in active development)
