%% --------------------------------Hello-------------------------------- %%
% This code details the UC part in our paper: Feature-driven Economic
% Improvement for Network-Constrained Unit Commitment: A Closed-Loop
% Predict-and-Optimize Framework.
%
% Please let me know if you have concerns about this code.
% It is my pleasure to discuss/explain with you.
%
% My academic email: xchen130@stevens.edu
% My personal email: chenxianbang@hotmail.com
%
% Please cite our paper if you use this code in your research:
%
% Xianbang Chen, Yafei Yang, Yikui Liu, and Lei Wu. "Feature-driven Economic
% Improvement for Network-Constrained Unit Commitment: A Closed-Loop
% Predict-and-Optimize Framework," IEEE Transaction on Power Systems, 2021.
%% --------------------------------Hello-------------------------------- %%
%
function[Rec_Decision_UC_I,...
         Rec_Decision_UC_P,...
         Rec_Decision_UC_R_h,...
         Rec_Decision_UC_R_c,...
         Rec_cost_UC_expected,...
         Rec_cost_UC_SUSD,...
         Rec_RES_prediction,...
         Rec_infea_UC_flag,...
         Rec_UC_time]...
= Step_02_DA_UC(H,...
                Current_day_intuition,...
                Scaler_load,...
                Scaler_SPG,...
                Scaler_WPG,...
                R_for_load,...
                R_for_RES,...
                First_day_intuition,...
                Final_day_intuition,...
                Method_flag)
%% -------------------------------Loading------------------------------- %%
Current_day_inform   = Current_day_intuition;
Remaining_day_inform = Final_day_intuition - Current_day_inform; 
First_day_iteration  = (Current_day_intuition - 1)*4 + 1;
Final_day_iteration  = Current_day_intuition*4;
[Number_gen,...
 ~,...
 ~,...
 Number_city,...
 Number_day,...
 ~,...
 Number_RES,...
 ~,...
 Number_point,...
 ~,...
 ~,...
 ~,...
 Data_Gen_price,...
 ~,...
 ~,...
 Data_load_city,...
 ~,...
 ~,...
 Data_feature,...
 ~,...
 ~,...
 ~,...
 ~] = CPO_Database_Belgium_bus24(First_day_iteration,...
                                 Final_day_iteration,...
                                 Scaler_load,...
                                 Scaler_SPG,...
                                 Scaler_WPG,...
                                 Method_flag);
load('UC_A_ineq');
load('UC_b_ineq');
load('UC_c');
Number_hour = 24;
%% -----------------------Prepare box for recorder---------------------- %%              
Rec_Decision_UC_I    = cell(Number_day, 1);
Rec_Decision_UC_P    = cell(Number_day, 1);
Rec_Decision_UC_R_h  = cell(Number_day, 1);
Rec_Decision_UC_R_c  = cell(Number_day, 1);
Rec_cost_UC_expected = zeros(Number_day, 1);
Rec_cost_UC_SUSD     = zeros(Number_day, 1);
Rec_RES_prediction   = H*Data_feature(:, First_day_iteration:Final_day_iteration);
Rec_infea_UC_flag    = zeros(Number_day, 1);
Rec_UC_time          = zeros(Number_day, 1);
%% -------------------------------Let's go------------------------------ %%
Version = 1;
for day = First_day_iteration:Final_day_iteration
    clear('yalmip');
    Index = day - First_day_iteration + 1;
    %% -----------------------------Decision---------------------------- %%
    % UC decision
    Decision_I          = binvar(Number_gen, Number_hour);
    Decision_I_SU       = binvar(Number_gen, Number_hour);
    Decision_I_SD       = binvar(Number_gen, Number_hour);
    Decision_P          = sdpvar(Number_gen, Number_hour);
    Decision_P_cost     = sdpvar(Number_gen, Number_hour);
    Decision_delta      = sdpvar(Number_gen*Number_point, Number_hour);
    Decision_R_h        = sdpvar(Number_gen, Number_hour);
    Decision_R_c        = sdpvar(Number_gen, Number_hour);
    Decision_R_all_req  = sdpvar(Number_hour, 1);
    Decision_R_load_req = sdpvar(Number_hour, 1);
    Decision_R_RES_req  = sdpvar(Number_hour, 1);
    % ED decision
    Decision_L_s = sdpvar(Number_hour, Number_city);
    Decision_L_r = sdpvar(Number_hour, Number_city);
    Decision_W_s = sdpvar(Number_hour, Number_RES);
    Decision_W_r = sdpvar(Number_hour, Number_RES);
    % All decision
    x = [Decision_I(:);
         Decision_I_SU(:);
         Decision_I_SD(:);
         Decision_P(:);
         Decision_P_cost(:);
         Decision_delta(:);
         Decision_R_h(:);
         Decision_R_c(:);
         Decision_R_all_req(:);
         Decision_R_load_req(:);
         Decision_R_RES_req(:);
         Decision_L_s(:);
         Decision_L_r(:);
         Decision_W_s(:);
         Decision_W_r(:)];
    %% -----------------------Constraints: general---------------------- %%
    CC_General = [UC_A_ineq*x <= UC_b_ineq];
    %
    %% -----------------------Constraints: special---------------------- %%
    CC_Special = [];
    % CC_Special_01: Load shedding limit
    Load_RUM     = Data_load_city{Number_hour*(day-1)+1:Number_hour*day, :};
    Country_Load = sum(Load_RUM,2);
    CC_Special   = CC_Special + [Decision_L_s(:) + Decision_L_r(:) == Load_RUM(:)];
    % CC_Special_02: RES curtailment limit
    RES_PRE     = Rec_RES_prediction(001:Number_RES*Number_hour, Index);
    Country_RES = zeros(Number_hour,1);
    for i_RES = 1:Number_RES
        Country_RES(:,1) = Country_RES(:,1)...
                         + RES_PRE((i_RES-1)*Number_hour+1:i_RES*Number_hour);
    end
    CC_Special = CC_Special + [Decision_W_s(:) + Decision_W_r(:) == RES_PRE];
    % CC_Special_03: Provided reseve
    CC_Special = CC_Special...
               + [Decision_R_load_req == R_for_load*Country_Load]...
               + [Decision_R_RES_req  == R_for_RES*Country_RES]...
               + [Decision_R_load_req + Decision_R_RES_req == Decision_R_all_req];
    %
    %% -------------------------Constraints: all------------------------ %%
    CC = CC_General + CC_Special;
    %
    %% ----------------------------Objective---------------------------- %%
    Cost_UC = UC_c'*x;
    %
    %% -----------------------------Solve it---------------------------- %%
    ops = sdpsettings('solver', 'gurobi');
    ops.gurobi.MIPGap = 1/100;
    tic;
    t1 = clock;
    optimize(CC, Cost_UC, ops);
    t2 = clock;
    toc;
    %% -----------------------------Value it---------------------------- %%
    Decision_I    = round(value(Decision_I));
    Decision_I_SU = round(value(Decision_I_SU));
    Decision_I_SD = round(value(Decision_I_SD));
    Decision_P    = round(value(Decision_P),5);
    Decision_P(Decision_P<=0) = 0;
    Decision_R_h  = round(value(Decision_R_h));
    Decision_R_h(Decision_R_h<=0) = 0;
    Decision_R_c  = round(value(Decision_R_c));
    Decision_R_c(Decision_R_c<=0) = 0;

    Cost_SU = Data_Gen_price(:,5)'*sum(Decision_I_SU,2);
    Cost_SD = Data_Gen_price(:,6)'*sum(Decision_I_SD,2);
    Cost_UC = value(Cost_UC);
    %% ------------------Seperate non-spinning reserve------------------ %%
    for i = 1:Number_gen
        for t = 1:Number_hour
            if (Decision_R_h(i,t)~=0) &&  (Decision_R_c(i,t)~=0)
                Decision_R_c(i,t) = 0;
            end
        end
    end
    %% ----------------------------Record it---------------------------- %%
    Rec_Decision_UC_I{Index}    = Decision_I;
    Rec_Decision_UC_P{Index}    = Decision_P;
    Rec_Decision_UC_R_h{Index}  = Decision_R_h;
    Rec_Decision_UC_R_c{Index}  = Decision_R_c;
    Rec_cost_UC_expected(Index) = Cost_UC;
    Rec_cost_UC_SUSD(Index)     = Cost_SU + Cost_SD;
    Rec_UC_time(Index)          = etime(t2,t1);
    %% ----------------------------Check UC----------------------------- %%
    if isnan(Cost_UC)
        Rec_infea_UC_flag(Index) = 1;
    end
    %% ----------------------------Display it--------------------------- %%  
    Infom_01 = ['First     day ===> ', num2str(First_day_intuition)];
    Infom_02 = ['Final     day ===> ', num2str(Final_day_intuition)];
    Infom_03 = ['Current   day ===> ', num2str(Current_day_inform), ' .V', num2str(Version)];
    Infom_04 = ['Remaining day ===> ', num2str(Remaining_day_inform)];
    disp('%%%%%%%%%%%%%%%%%%%%%%% UC MODE %%%%%%%%%%%%%%%%%%%%%%%');
    disp(Infom_01);
    disp(Infom_02);
    disp(Infom_03);
    disp(Infom_04);
    disp('%%%%%%%%%%%%%%%%%%%%%%% UC MODE %%%%%%%%%%%%%%%%%%%%%%%');
    Version = Version + 1;
    if Version > 4 
        Version = 1;
    end
    yalmip('clear');
end
end