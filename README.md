# Update as of September 2024
Some colleagues recently pointed out that the code produces NaN results. This issue is due to current limitations in YALMIP's support for solver parameter tuning. 

To address this, please try commenting out the following lines in Step 01 and Step 02:

```matlab
ops.gurobi.MIPGap    = Solver_gap/100;
ops.gurobi.TimeLimit = Solver_time*60;
ops.cplex.mip.tolerances.mipgap = Solver_gap/100;
ops.cplex.timelimit = Solver_time*60;
ops.mosek.MSK_DPAR_MIO_TOL_REL_GAP = Solver_gap/100;
ops.mosek.MSK_DPAR_MIO_MAX_TIME = Solver_time*60;
```

The code has been updated accordingly. Thank you for your feedback!

# Closed_Loop_NCUC_Dataset-Load_RES_Feature_System
The followings are the dataset and the codes for the paper entitled "Feature-Driven Economic Improvement for Network-Constrained Unit Commitment: A Closed-Loop Predict-and-Optimize Framework"

If they are helpful in your research, please cite our paper:
X. Chen, Y. Yang, Y. Liu and L. Wu, "Feature-Driven Economic Improvement for Network-Constrained Unit Commitment: A Closed-Loop Predict-and-Optimize Framework," in IEEE Transactions on Power Systems, vol. 37, no. 4, pp. 3104-3118, July 2022, doi: 10.1109/TPWRS.2021.3128485.

The data is collected from a Belgian ISO. This dataset is saved as .xlsx and includes:

* Day-ahead prediction and actual realization of Belgian load. (From 2018/01/01 to 2020/12/31) [Load.xlsx](https://github.com/asxadf/Closed_Loop_NCUC_Dataset/files/7584372/Load.xlsx)

* Day-ahead prediction and actual realization of 13 solar power farms in Belgium. (From 2018/01/01 to 2020/12/31) [Solar_power_farm.xlsx](https://github.com/asxadf/Closed_Loop_NCUC_Dataset/files/7584373/Solar_power_farm.xlsx)

* Day-ahead prediction and actual realization of 7 wind power farms in Belgium. (From 2018/01/01 to 2020/12/31) [Wind_power_farm.xlsx](https://github.com/asxadf/Closed_Loop_NCUC_Dataset/files/7584374/Wind_power_farm.xlsx)

* Configurations of modified IEEE RTS 24-bus system. [System_IEEE_24_bus.xlsx](https://github.com/asxadf/Closed_Loop_NCUC_Dataset-Load_RES_Feature_System/files/7314314/System_IEEE_24_bus.xlsx)

* Configurations of 5655-bus system. [System_ISO_5655_bus.xlsx](https://github.com/asxadf/Closed_Loop_NCUC_Dataset_Load_RES_Feature_System/files/7314468/System_ISO_5655_bus.xlsx)

* Well-collected feature vectors. [Feature.xlsx](https://github.com/asxadf/Closed_Loop_NCUC_Dataset-Load_RES_Feature_System/files/7314316/Feature.xlsx)

Note that the load-RES data is collected every 15 minutes, so we add the subhour label to distinguish them.

To show our modification on IEEE RTS 24-bus system, we plot a map. Just check it out! [Map.pdf](https://github.com/asxadf/Closed_Loop_NCUC_Dataset-Load_RES_Feature_System/files/7314204/Map.pdf)

Recently, we presented the work. Just check it out! [OR_Presentation.pdf](https://github.com/asxadf/Closed_Loop_NCUC_Dataset/files/7739919/OR_Presentation.pdf)

We believe it is meaningful and helpful to enable the code open-access. So we upload the codes for the 24-bus case here. It requires MATLAB as the platform, GUROBI as the solver, and YALMIP to call GUROBI.

If you are interested in our data, case studies, and codes, please feel free to contact me at xchen130@stevens.edu. It's my pleasure to share them with you. 🤨
