# energyscope_Samoa

Running the program:

- requires glpsol solver to be installed

Run the program with

```cmd
cd STEP_2_Energy_Model
glpsol -m 10Dec_ESTD_model.mod -d 10Dec_ESTD_data.dat -d ESTD_8TD.dat -o ses_main.out
```
