# Indicator catalog

Every recap fills every row below. Thresholds are the publisher's own rule or
the standard textbook reading. Do not add others.

FRED series IDs let you pull any series at
`https://fred.stlouisfed.org/series/<ID>`.

## Definitions

- **Recession (official).** The NBER Business Cycle Dating Committee defines
  a recession as a significant decline in economic activity that is spread
  across the economy and lasts more than a few months. It judges depth,
  diffusion, and duration, and announces dates months after the fact. Its
  record is FRED `USREC`.
- **Recession (rule of thumb).** Two consecutive quarters of falling real
  GDP. This is a common shorthand. It is not the official definition.
- **Inflation.** A sustained rise in the general price level. The Fed targets
  2% inflation measured by the PCE price index. "Core" excludes food and
  energy because they are volatile, so core shows the underlying trend.
- **Year over year (y/y)** compares to the same month a year earlier.
  **Month over month (m/m)** compares to the prior month. A 0.3% m/m pace
  compounds to about 3.7% a year.

## Inflation and policy

| Indicator | Publisher | FRED ID | Cadence | Textbook reading |
| --- | --- | --- | --- | --- |
| PCE price index | BEA | `PCEPI` | Monthly | Fed's 2% target gauge. Above 2% means inflation runs hot |
| Core PCE | BEA | `PCEPILFE` | Monthly | Underlying trend the Fed watches most closely |
| CPI | BLS | `CPIAUCSL` | Monthly | Consumer prices. Usually runs above PCE |
| Core CPI | BLS | `CPILFESL` | Monthly | CPI less food and energy |
| Federal funds target range | FOMC | `DFEDTARL`, `DFEDTARU` | 8 meetings a year | Raising fights inflation and slows growth. Cutting supports growth |
| Interest on reserve balances | Fed Board | `IORB` | With each decision | The Fed's main tool for holding rates in the range |
| Fed funds futures odds | CME FedWatch | None | Daily | Market-implied probability of the next decision |

## Recession checklist

The first six rows are the monthly series the NBER committee says it weighs
most heavily.

| # | Indicator | Publisher | FRED ID | Cadence | Recession signal |
| --- | --- | --- | --- | --- | --- |
| 1 | Real personal income less transfers | BEA | `W875RX1` | Monthly | Sustained decline |
| 2 | Nonfarm payroll employment | BLS | `PAYEMS` | Monthly, first Friday | Monthly job losses, sustained |
| 3 | Household survey employment | BLS | `CE16OV` | Monthly | Sustained decline |
| 4 | Real personal consumption expenditures | BEA | `PCEC96` | Monthly | Sustained decline |
| 5 | Real manufacturing and trade sales | BEA | `CMRMTSPL` | Monthly | Sustained decline |
| 6 | Industrial production | Fed (G.17) | `INDPRO` | Monthly, mid-month | Sustained decline |
| 7 | Real GDP growth | BEA | `A191RL1Q225SBEA` | Quarterly: advance, second, third estimates | Negative. Two negative quarters is the rule of thumb |
| 8 | Real GDI growth | BEA | `A261RL1Q225SBEA` | Quarterly | Negative. Cross-checks GDP |
| 9 | Unemployment rate | BLS | `UNRATE` | Monthly | Rising steadily |
| 10 | Sahm rule | FRED (Claudia Sahm) | `SAHMREALTIME` | Monthly | 3-month average unemployment rate 0.50 points or more above its low of the prior 12 months |
| 11 | Initial jobless claims | Labor Dept | `ICSA` | Weekly, Thursday | Sustained rise in the 4-week average from its cycle low |
| 12 | Continuing claims | Labor Dept | `CCSA` | Weekly | Sustained rise |
| 13 | Yield curve, 10-year minus 3-month | Treasury, NY Fed | `T10Y3M` | Daily | Inverted (below zero). The NY Fed recession model uses this spread |
| 14 | Yield curve, 10-year minus 2-year | Treasury | `T10Y2Y` | Daily | Inverted (below zero) |
| 15 | ISM Manufacturing PMI | ISM | None | Monthly, first business day | Below 50 means manufacturing contracts. ISM states the level consistent with overall economic expansion in each report |
| 16 | ISM Services PMI | ISM | None | Monthly, third business day | Below 50 means services contract |
| 17 | Conference Board LEI | Conference Board | None | Monthly | Its "3Ds" rule: six-month annualized decline beyond 4.3% with half or fewer components rising |
| 18 | Retail sales | Census | `RSAFS` | Monthly, mid-month | Sustained decline after inflation |
| 19 | Consumer sentiment | Univ. of Michigan | `UMCSENT` | Monthly, preliminary and final | Sharp, sustained drop. Sentiment alone does not date recessions |
| 20 | Capacity utilization | Fed (G.17) | `TCU` | Monthly | Falling steadily |
| 21 | Richmond Fed SOS indicator | Richmond Fed | None | Weekly | Above 0.2 |
| 22 | High-yield credit spread | ICE BofA | `BAMLH0A0HYM2` | Daily | Rapid widening shows credit stress |
| 23 | VIX | Cboe | `VIXCLS` | Daily | Market fear gauge. Above 30 is high stress. It is not a recession signal by itself |
| 24 | NBER declaration | NBER | `USREC` | Irregular | A declared recession settles the question |

## Reading the checklist

- One indicator never decides the verdict. The NBER looks for a decline that
  is deep, broad, and lasting.
- The labor rows (2, 3, 9, 10, 11, 12) and the output rows (6, 7) carry the
  most weight. Leading rows (13, 14, 15, 17, 19) warn of risk. They do not
  show a recession in progress.
- Each GDP estimate can be revised. Say which estimate a figure is.
