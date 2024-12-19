# Lab 3 - Shiny

I am an annoying client today. I want a web application to see emergency services stays.

## Data description

Similar dataset as Lab 2, but I have already cleaned it (no traps this time).

| Variable | Label | Values |
| ----------- | ----------- | ----------- |
| region | Region where the service is located | Auvergne-Rhône-Alpes de Provence, Occitanie-sur-Bretagne, Québecorse |
| service | Name of the emergency service | Autonoesis, Conifère, Griffon, Grylle, Houle, Valdrin, Véhémence |
| id | Identifie of the patient | Numerical variable |
| severity | Severity of the patient's disease (i.e. how bad it is) | (less severe) 1 <==> 5 (more severe) |
| discharge_mode | Mode of discharge from the service (i.e. how the patient got out) | Died, home, hospitalised, transferred to other hospital |
| arrival_mode | Mode of arrival in the service (i.e. how the patient came) | Ambulance, Ambulance + firefighters, Ambulance + life support, Cops, Helicopter, Personal |
| los | Length of stay in the service, in minutes | Numerical variable |
| diagnostic | Primary diagnostic of the patient (i.e. his disease) | Too many |
| age | Age of patient | Numerical variable |
| entry | Time of entry | Date |
| exit | Time of exit | Date |
| complexity | Complexity of the patient's disease (i.e. how complex it is to treat) | (less complex) 1 <==> 10 (more complex) |
| cost | Cost of the stay in the service | Numerical variable |
| ald | Patient with a long-term illness (affection longue durée) | 1 = yes, 0 = no|

## What I need

- An introductory page where you explain what the data is about
  - Put an image
- The full table
  - Table must be downloadable
  - Must be filterable (according to the filters below)
- Information about ALD patients vs. non-ALD
  - Age
  - Differences in costs
  - Severity/complexity
  - Length of stay
- About costs
  - Age
  - Length of Stay
  - By discharge mode
- At least one 3D graph because it looks cool
- By service: distribution of length of stay
- By region: distribution of length of stay
- Factors associated with staying at least 6 hours in a service

I want to be able to filter depending on these groups:

- Everybody
- People over 75
- People under 18
- All emergency services
- Only one emergency service
- All regions
- One region

Make it look good.
