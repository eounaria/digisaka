
/* ================================================================
   DIGISAKA — GLOBAL USE CASE CONTEXT LAYER
   One selector controls every context-aware module. Existing data is
   this layer only chooses what is shown.
   ================================================================ */
currentUseCase = 'black-sigatoka';

const GLOBAL_USE_CASES = {
  'black-sigatoka': {
    label:'Black Sigatoka', icon:'🍌', crop:'Banana', disease:'Black Sigatoka',
    pathogen:'Pseudocercospora fijiensis',
    ontology:'Black Sigatoka Knowledge Ontology',
    short:'Banana disease management and early-stage knowledge workspace.'
  },
  'rice': {
    label:'Rice', icon:'🌾', crop:'Rice', disease:'Rice Blast',
    pathogen:'Magnaporthe oryzae',
    ontology:'Rice Knowledge Ontology',
    short:'Rice crop health, disease, treatment, and agricultural knowledge workspace.'
  },
  'corn': {
    label:'Corn', icon:'🌽', crop:'Corn', disease:'Northern Corn Leaf Blight',
    pathogen:'Exserohilum turcicum',
    ontology:'Corn Knowledge Ontology',
    short:'Corn crop health, disease, treatment, and agricultural knowledge workspace.'
  }
};

