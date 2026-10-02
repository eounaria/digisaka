// Starting ontology for every use case; admins edit it afterwards in the Ontologies screen.
export const DEFAULT_CLASSES = [
  ['Crop', '#2e3192', 'The plant being grown'],
  ['Disease', '#ef6a16', 'A disease affecting the crop'],
  ['Pathogen', '#48d20d', 'The organism that causes the disease'],
  ['Symptom', '#d51bd8', 'What the farmer sees on the plant'],
  ['Disease Stage', '#8520e1', 'How far the disease has progressed'],
  ['Environment', '#293394', 'Conditions that influence the disease'],
  ['Treatment', '#e9c318', 'How the disease is managed'],
  ['Region', '#0f8f8a', 'Where the disease is observed'],
  ['Source', '#5b6475', 'A document or report that describes the crop'],
];

export const DEFAULT_RELATIONS = [
  ['Source', 'Crop', 'describes'],
  ['Crop', 'Disease', 'affected by'],
  ['Disease', 'Pathogen', 'caused by'],
  ['Disease', 'Symptom', 'shows'],
  ['Symptom', 'Disease Stage', 'indicates'],
  ['Disease Stage', 'Environment', 'influenced by'],
  ['Disease', 'Treatment', 'managed with'],
  ['Treatment', 'Crop', 'protects'],
  ['Disease', 'Region', 'observed in'],
];

export const DEFAULT_FOLDERS = ['Healthy', 'Early Stage', 'Moderate Stage', 'Advanced Stage'];
