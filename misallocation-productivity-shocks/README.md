# Common productivity shocks and misallocation

*Independent research code. This project was not a data task, so it has no `instruction.md`.*

## Question

Does aggregate ("common") productivity affect how efficiently capital is allocated across firms?

## Method

A dynamic, stochastic partial-equilibrium model of heterogeneous firms:

- Productivity is the sum of a firm-specific AR(1) component and a common AR(1) component.
- Firms face convex capital adjustment costs, partially irreversible investment, and capital prices that vary with firm size and productivity.
- Policy functions are computed by value function iteration.
- A panel of firms is simulated, and misallocation is measured as the dispersion of the marginal revenue product of capital, over a range of values for average common productivity.

## Headline result

Doubling common productivity raises output directly and also reduces misallocation by 14%, in economies where larger firms face lower capital costs. After a 10% rise in average common productivity, more than half of the resulting growth comes from better capital allocation.

## Layout

```
code/
  Model.jl                  model parameters and shock processes (module DpModel)
  PolicyCalculation.jl      value function iteration (module PolicyCalc)
  Simulation.jl             time-series simulation (module SimulationTS)
  Heterogeneous.jl          heterogeneous-firm simulation and aggregation (module Heter)
  misallocation_demo.ipynb  runs the model end to end
output/                     results written by the notebook
report/report.pdf           full paper
report/notebook_export.pdf  static copy of the notebook
Project.toml                Julia dependencies
```

## How to run

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using IJulia; notebook(dir="code")'
```

Then open `misallocation_demo.ipynb`. Written for Julia 1.6. The heterogeneous-firm simulation over the productivity grid is the slow step.

## Data availability

No data are needed. All results come from model simulation.

## Contact

Alireza Shirkhodaee · ar.shirkhodaee@gmail.com
