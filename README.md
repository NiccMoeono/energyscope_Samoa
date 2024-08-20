# energyscope_Samoa

Running the program:

- requires glpsol solver to be installed

Run the program with

```cmd
cd STEP_2_Energy_Model
glpsol -m ESTD_model.mod -d ESTD_data.dat -d ESTD_12TD.dat -o ses_main.out
```
