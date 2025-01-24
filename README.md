# Closed-Loop Predict-and-Optimize Framework

### Update (December 2024)
We have published a more comprehensive work on this topic, including a bi-level programming-based approach and a literature review. If you have any questions, feel free to reach out!

- [X. Chen, Y. Liu, and L. Wu, "Towards Improving Unit Commitment Economics: An Add-On Tailor for Renewable Energy and Reserve Predictions," *IEEE Transactions on Sustainable Energy*, vol. 15, no. 4, pp. 2547-2566, Oct. 2024.](https://ieeexplore.ieee.org/abstract/document/10592660)

### Update (September 2024)
Some colleagues have pointed out that the code might produce NaN results. This occurs due to limitations in YALMIP's support for solver parameter tuning.

To fix this, please **comment out** the following lines in **Step 01** and **Step 02**:

```matlab
ops.gurobi.MIPGap    = Solver_gap/100;
ops.gurobi.TimeLimit = Solver_time*60;
ops.cplex.mip.tolerances.mipgap = Solver_gap/100;
ops.cplex.timelimit = Solver_time*60;
ops.mosek.MSK_DPAR_MIO_TOL_REL_GAP = Solver_gap/100;
ops.mosek.MSK_DPAR_MIO_MAX_TIME = Solver_time*60;
```

We have updated the code accordingly. Thank you for your feedback!

---

## Dataset: Load, Renewables, and Feature System

Below are the datasets and codes accompanying the paper:

- [X. Chen, Y. Yang, Y. Liu, and L. Wu, "Feature-Driven Economic Improvement for Network-Constrained Unit Commitment: A Closed-Loop Predict-and-Optimize Framework," *IEEE Transactions on Power Systems*, vol. 37, no. 4, pp. 3104–3118, July 2022.](https://ieeexplore.ieee.org/document/9617122)

If you find these resources helpful in your research, please cite our paper. 

### Contents
1. **Load.xlsx**  
   Day-ahead forecasts and actual realizations of Belgian load from 2018/01/01 to 2020/12/31.
   
2. **Solar_power_farm.xlsx**  
   Day-ahead forecasts and actual realizations of 13 solar farms in Belgium (2018/01/01 to 2020/12/31).
   
3. **Wind_power_farm.xlsx**  
   Day-ahead forecasts and actual realizations of 7 wind farms in Belgium (2018/01/01 to 2020/12/31).
   
4. **System_IEEE_24_bus.xlsx**  
   Configurations of the modified IEEE RTS 24-bus system.
   
5. **System_ISO_5655_bus.xlsx**  
   Configurations of the 5655-bus system.
   
6. **Feature.xlsx**  
   Well-collected feature vectors.
   
> **Note:** The load and renewable energy data are collected at 15-minute intervals, hence the sub-hour labels.

---

## Additional Files

- **[Map.pdf](https://github.com/asxadf/Closed_Loop_NCUC_Dataset-Load_RES_Feature_System/files/7314204/Map.pdf)**  
  Illustrates modifications made to the IEEE RTS 24-bus system.

- **[OR_Presentation.pdf](https://github.com/asxadf/Closed_Loop_NCUC_Dataset/files/7739919/OR_Presentation.pdf)**  
  Our recent presentation on this work.

---

## Code and Requirements

We have made our code open-access to foster further research. The provided MATLAB scripts solve the 24-bus case study and require:

- **MATLAB**  
- **GUROBI** (as the solver)  
- **YALMIP** (for calling GUROBI from MATLAB)  

If you encounter any issues or would like the datasets and codes for larger systems, please feel free to contact me at [xchen130@stevens.edu](mailto:xchen130@stevens.edu). It’s my pleasure to share and discuss these resources!

---

**Thank you for your interest in our work!**  
If you use these datasets or the code in your research, kindly cite the relevant publications.  
