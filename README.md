# M3SWTA: Multi-Missile Multi-Stage Sensor-Weapon-Target Assignment

Official MATLAB implementation of **KCEA** (Knowledge-guided Competitive Evolutionary Algorithm) for the multi-solution sensor-weapon-target assignment (S-WTA) problem, from the paper:

> W. Li, X. Yao, K. Li, R. Wang, and T. Zhang, "Knowledge-Guided Competitive Evolutionary Algorithm for Multi-Solution Sensor-Weapon-Target Assignment Problem," *IEEE Transactions on Evolutionary Computation*, 2026.
> DOI: [10.1109/TEVC.2026.3653800](https://doi.org/10.1109/TEVC.2026.3653800)

The published paper PDF is included in this repository ([202601-TEVC-Knowledge-Guided Competitive Evolutionary Algorithm for Multi-Solution Sensor-Weapon-Target Assignment Problem.pdf](202601-TEVC-Knowledge-Guided Competitive Evolutionary Algorithm for Multi-Solution Sensor-Weapon-Target Assignment Problem.pdf)).

## Overview

Modern air-defense engagement requires jointly allocating sensors and weapons to targets across consecutive guidance stages, while keeping **multiple high-quality assignment plans** available for the command decision loop. KCEA extracts reusable allocation knowledge from the evolving population and embeds it into a competitive evolutionary framework, so that several well-separated solutions are maintained throughout the search instead of a single optimum.

## Repository Structure

```
M3SWTA/
├── main.m                 % entry script: loads a scenario and runs KCEA
├── KCEA/                  % the KCEA solver (operator, environmental selection, ...)
├── PublicFun/             % problem modeling, objectives, relay guidance, plotting
├── Scenario/              % 12 test scenarios (Info_enemy_*.mat)
└── 202601-TEVC-*.pdf      % the published paper
```

## Quick Start

Requirements: MATLAB R2020b or later (no toolbox required).

1. Open MATLAB in this folder.
2. Run:

```matlab
main
```

`main.m` loads `Scenario/Info_enemy_1.mat` by default. To switch scenarios, change the `Prob.scenarioFile` field:

```matlab
Prob.scenarioFile = '.\Scenario\Info_enemy_10.mat';
```

Key problem options in `main.m`:

| Option | Meaning |
|--------|---------|
| `Prob.dT` | discretization time granularity (seconds) |
| `Prob.flagAllowMultiMissile` | whether multiple missiles per target are allowed |
| `Prob.modeFire` | 1 = concentrated fire, 2 = distributed fire |

Population size and evaluation budget are set automatically from the scenario (`PopSize = 2*Target.N`, `MaxFEs = 100*Target.N`).

## Citation

If this code helps your research, please cite:

```bibtex
@article{Li2026KCEA,
  author  = {Li, Wenhua and Yao, Xingyi and Li, Kaiwen and Wang, Rui and Zhang, Tao},
  title   = {Knowledge-Guided Competitive Evolutionary Algorithm for Multi-Solution Sensor-Weapon-Target Assignment Problem},
  journal = {IEEE Transactions on Evolutionary Computation},
  year    = {2026},
  doi     = {10.1109/TEVC.2026.3653800}
}
```

## Contact

- Wenhua Li (`liwenhua1030@aliyun.com`)
