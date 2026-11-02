import { BASE, fail, ok, authed, isValidWeek } from './common.js';

const PRODUCTS = [
  {
    id: 'opt-protectant',
    name: 'Mancozeb 80 WP',
    group: 'Contact, multi-site protectants',
    active_ingredient: 'Mancozeb',
    formulation: 'Wettable powder (WP)',
    frac_code: 'M03',
    mode_of_action: 'Multi-site contact activity',
    mobility: 'Contact',
    price: '₱1,270 per kg',
    efficacy: 'Preventive cover on young leaves',
    rate: 'Not provided',
    rainfast: 'Not provided',
    interval: 'Not provided',
    manufacturer: 'Not recorded',
    recommended: true,
    eligibility: 'Eligible in prototype data',
    resistance_note: 'Used 2 times on this line in the last 6 weeks; 1 application left under the sample limit of 3 per season.',
    evidence: 'Sample evidence only; not validated product guidance.',
  },
  {
    id: 'opt-chlorothalonil',
    name: 'Chlorothalonil 720 SC',
    group: 'Contact, multi-site protectants',
    active_ingredient: 'Chlorothalonil',
    formulation: 'Suspension concentrate (SC)',
    frac_code: 'M05',
    mode_of_action: 'Multi-site contact activity',
    mobility: 'Contact',
    price: '₱1,780 per L',
    efficacy: 'Preventive cover',
    rate: 'Not provided',
    rainfast: 'Not provided',
    interval: 'Not provided',
    manufacturer: 'Not recorded',
    recommended: false,
    eligibility: 'Eligible in prototype data',
    resistance_note: 'No prior use recorded in this sample history.',
    evidence: 'Sample evidence only; not validated product guidance.',
  },
  {
    id: 'opt-azoxystrobin',
    name: 'Azoxystrobin 250 SC',
    group: 'Systemic fungicides',
    active_ingredient: 'Azoxystrobin',
    formulation: 'Suspension concentrate (SC)',
    frac_code: '11',
    mode_of_action: 'QoI inhibitor',
    mobility: 'Systemic',
    price: '₱2,100 per L',
    efficacy: 'Not provided',
    rate: 'Not provided',
    rainfast: 'Not provided',
    interval: 'Not provided',
    manufacturer: 'Not recorded',
    recommended: false,
    eligibility: 'Excluded in prototype data',
    resistance_note: 'Sample season limit reached.',
    evidence: 'Sample evidence only; not validated product guidance.',
  },
  {
    id: 'opt-propiconazole',
    name: 'Propiconazole 250 EC',
    group: 'Systemic fungicides',
    active_ingredient: 'Propiconazole',
    formulation: 'Emulsifiable concentrate (EC)',
    frac_code: '3',
    mode_of_action: 'DMI inhibitor',
    mobility: 'Systemic',
    price: '₱1,950 per L',
    efficacy: 'Not provided',
    rate: 'Not provided',
    rainfast: 'Not provided',
    interval: 'Not provided',
    manufacturer: 'Not recorded',
    recommended: false,
    eligibility: 'Excluded in prototype data',
    resistance_note: 'FRAC 3 appears in consecutive sample cycles.',
    evidence: 'Sample evidence only; not validated product guidance.',
  },
  {
    id: 'opt-tilt',
    name: 'Tilt 250 EC',
    group: 'Systemic fungicides',
    active_ingredient: 'Propiconazole',
    formulation: 'Emulsifiable concentrate (EC)',
    frac_code: '3',
    mode_of_action: 'DMI inhibitor',
    mobility: 'Systemic',
    price: 'Not provided',
    efficacy: 'Not provided',
    rate: 'Not provided',
    rainfast: 'Not provided',
    interval: 'Not provided',
    manufacturer: 'Not recorded',
    recommended: false,
    eligibility: 'Excluded in prototype data',
    resistance_note: 'Sample exclusion: used in consecutive sample cycles.',
    evidence: 'Sample evidence only; not validated product guidance.',
  },
];

const EXCLUDED = [
  { product_id: 'opt-azoxystrobin', name: 'Azoxystrobin 250 SC', frac_code: '11', reason: 'Sample season cap reached.' },
  { product_id: 'opt-propiconazole', name: 'Propiconazole 250 EC', frac_code: '3', reason: 'FRAC 3 appears in consecutive sample cycles.' },
  { product_id: 'opt-tilt', name: 'Tilt 250 EC', frac_code: '3', reason: 'Used in consecutive sample cycles.' },
];

const SAMPLE = {
  label: 'Sample data for demo. Not validated guidance or label information.',
  recommended_action: {
    preventive: true,
    mechanical: true,
    treatment: false,
    monitor: false,
    provisional_label: 'Provisional threshold',
    summary: 'Protect young leaves and remove heavily infected leaves. Reassess after this scan week.',
  },
  weather: {
    rainfall_7d_mm: 42,
    humidity_average_pct: 88,
    leaf_wetness_hours_daily: 11,
    infection_risk: 'High',
    forecast: [
      { day: 'Mon', rainfall_mm: 2 },
      { day: 'Tue', rainfall_mm: 8 },
      { day: 'Wed', rainfall_mm: 12 },
      { day: 'Thu', rainfall_mm: 0 },
      { day: 'Fri', rainfall_mm: 10 },
    ],
    forecast_rain_days: 4,
  },
  spray_history: [
    { date: '2026-10-14', name: 'Propiconazole', mode: 'Systemic', frac_code: '3', status: 'Restricted' },
    { date: '2026-09-29', name: 'Propiconazole', mode: 'Systemic', frac_code: '3', status: 'Restricted' },
    { date: '2026-09-15', name: 'Mancozeb', mode: 'Contact', frac_code: 'M03', status: 'OK' },
    { date: '2026-09-01', name: 'Azoxystrobin', mode: 'Systemic', frac_code: '11', status: 'Restricted' },
  ],
  frac_history: [
    { frac_code: '3', uses: 2, limit: 3, status: 'Restricted', reason: 'Used in 2 consecutive cycles.' },
    { frac_code: '11', uses: 3, limit: 3, status: 'Restricted', reason: 'Sample season cap reached.' },
    { frac_code: 'M03', uses: 2, limit: 3, status: 'OK', reason: 'One sample application remains.' },
  ],
  products: PRODUCTS,
  excluded: EXCLUDED,
};

const copy = (value) => JSON.parse(JSON.stringify(value));

export function prototypeRoutes(store) {
  const lineWeek = (params) => {
    if (!store.data.lines[params.id]) return fail(404, 'unknown_line', `No line ${params.id}`);
    if (!isValidWeek(params.week)) return fail(400, 'invalid_week', `${params.week} is not a week key`);
    return null;
  };

  return [
    {
      method: 'GET', path: `${BASE}/prototype/lines/:id/weeks/:week`,
      handle: authed(({ params }) => {
        const bad = lineWeek(params);
        if (bad) return bad;
        const proposal = store.data.lines[params.id].proposals.find((item) => item.week === params.week);
        return ok({
          line_id: params.id,
          week: params.week,
          sample: true,
          ...copy(SAMPLE),
          selected_option_id: proposal?.option_id ?? 'opt-protectant',
        });
      }),
    },
    {
      method: 'POST', path: `${BASE}/prototype/lines/:id/weeks/:week/selection`,
      handle: authed(({ params, body }) => {
        const bad = lineWeek(params);
        if (bad) return bad;
        const product = PRODUCTS.find((item) => item.id === body?.option_id);
        if (!product) return fail(400, 'invalid_option', 'Choose a product from the prototype catalog.');
        const proposal = store.data.lines[params.id].proposals.find((item) => item.week === params.week);
        if (!proposal) return fail(409, 'proposal_required', 'A treatment proposal is required before selecting a prototype product.');
        proposal.option_id = product.id;
        return ok({ selected_option_id: product.id, product: copy(product), sample: true });
      }),
    },
  ];
}

export function productForOption(optionId) {
  return PRODUCTS.find((item) => item.id === optionId) ?? null;
}
