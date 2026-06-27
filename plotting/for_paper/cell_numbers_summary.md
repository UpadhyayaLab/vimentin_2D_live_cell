# Cell numbers used for BARCODE and FDD analysis

This note records, with ground-truth per-cell data, how many cells each analysis
used per condition for the vimentin 2D live-cell paper, and explains every place
the counts disagree.

Two independent analyses are reported per cohort:

- **FDD** — the metric-over-time analysis in this MATLAB repo.
- **BARCODE** — Kurtosis and Reduced/Norm Divergence, produced by a separate
  Python pipeline whose source is not available here; only its output CSVs on the
  J: drive are.

## Data sources

- **FDD N** — derived from the `cell_number` arrays in
  `vimentin_2D_live_cell_dir_filenames.m`, aggregated per condition in
  `vimentin_2D_live_cells_postprocessing_combined_data.m`
  (true N = `numel(FDD{i})`, the sum of `params.ncells` across days via
  `IO/read_in_combine_results.m`).
- **BARCODE N** — taken two ways and cross-checked:
  - the `Number of … Cells` columns in
    `RDS vs Time Plot Data\*.csv`, and
  - the unique `Cell Number` IDs in `Violin Plot Data\*.csv` — the per-cell
    source, i.e. the authoritative cohort list.

  Both under
  `J:\FF\vim_data\Vimentin_2D_tighter_cropping\Vimentin_2D\BARCODE Analysis for Figures\`.

## Summary table

| Condition | FDD | BARCODE Kurtosis | BARCODE Divergence |
|---|---|---|---|
| PLL (non-activated) | **18** | 15 | **18** |
| CD3 (activated) | **32** | 27¹ (RDS CSV says 26) | **35** |
| DMSO | **21** | 17 | **21** |
| Ciliobrevin | **19** | 17 | **19** |

**Headline:** FDD and BARCODE-Divergence agree for 3 of 4 conditions
(PLL 18, DMSO 21, Ciliobrevin 19). CD3 is the only condition where they differ,
and the difference is entirely accounted for by FDD's 20221103 exclusions
(Discrepancy 1). BARCODE Kurtosis is a consistently smaller, separately-selected
cohort.

N is **constant over time** in every RDS-vs-time CSV, so all differences below are
fixed-cohort (inclusion-criterion) differences — not cells dropping out over time.

## Discrepancies

### 1. FDD CD3 (32) vs BARCODE Divergence CD3 (35) — fully explained

The 3-cell gap is exactly the cells FDD excluded from the 20221103 aCD3 dataset.
FDD used `cell_number = {1,2,3,5,8,9}` (6 cells, dropping 4/6/7); BARCODE
Divergence kept all of 20221103 cells 1–9. So `32 + {4,6,7} = 35`. Confirmed
cell-by-cell against `CD3 Norm Divergence.csv`.

### 2. PLL N matches (18 = 18) but the cohorts differ

The counts tie by coincidence — they are not the same 18 cells:

- 20220623 PLL: FDD includes cell 4; BARCODE Divergence excludes it (`{1,2,3,5}`).
- 20221103 PLL: FDD excludes cell 4 (`{1,2,3,5}`); BARCODE Divergence includes it.

Each side drops one cell the other keeps, so the totals are equal. Worth a
footnote in any methods text: "same N" here does not mean "same cells."

### 3. BARCODE Kurtosis uses a smaller, differently-selected cohort

Kurtosis < Divergence for every condition (PLL 15, CD3 27, DMSO 17, Cilio 17).
It is not a strict subset of the Divergence cohort — Kurtosis sometimes includes
a cell that Divergence drops (e.g. PLL 20220623 cell 4). The selection logic
lives in the BARCODE Python pipeline, which is unavailable here, so this can only
be flagged, not resolved from the data on hand.

Cells present in Divergence but absent from Kurtosis:
- CD3: 20220719 {3,5,7,9}, 20221103 {3,6,7}, 20230203 {3}.
- Ciliobrevin Kurtosis missing cells 5, 10.
- DMSO Kurtosis missing cells 5, 9, 12, 21.

### 4. CD3 Kurtosis off-by-one (violin 27 vs RDS CSV 26)

`CD3 Kurtosis.csv` (violin/per-cell source) has 27 unique cells, but
`Activated vs Non-Activated Cells Kurtosis All Cells.csv` reports N = 26. One cell
in the scatter/violin source is missing from the time-averaged curve count. This
is a source-side bookkeeping issue to reconcile in the BARCODE pipeline.

### 5. Dynein Kurtosis RDS CSV has no N columns

`Dynein Inhibition Cells Kurtosis All Cells.csv` contains no `Number of … Cells`
column, so `report_sample_sizes_for_paper.m` cannot recover its N from that file.
The only source is the violin data: **Ciliobrevin Kurtosis = 17, DMSO Kurtosis =
17**. (The other three RDS CSVs do carry the N columns.)

## Action items at the data source (BARCODE pipeline, not this repo)

- Reconcile CD3 Kurtosis 26 vs 27 (Discrepancy 4).
- Add the `Number of … Cells` columns to the Dynein Kurtosis RDS CSV
  (Discrepancy 5).
- Decide whether the FDD and BARCODE cohorts should be harmonized (CD3 32 vs 35,
  and the PLL cell-4 swap) or reported as analysis-specific N with a footnote.

---

¹ Violin (per-cell) source shows 27 unique CD3 cells; the RDS-vs-time CSV reports
26. See Discrepancy 4.
