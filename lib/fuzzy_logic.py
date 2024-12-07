from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
import skfuzzy as fuzz
from skfuzzy import control as ctrl

app = FastAPI()

# Allow CORS for Dart app (running in the browser)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace "*" with specific origins if needed
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

# Define Fuzzy Logic Antecedents and Consequents
rhythm_ctrl = ctrl.Antecedent(np.arange(0, 11, 1), 'rhythm')
stress_ctrl = ctrl.Antecedent(np.arange(0, 11, 1), 'stress')
duration_ctrl = ctrl.Antecedent(np.arange(0, 11, 1), 'duration')
environment_ctrl = ctrl.Antecedent(np.arange(0, 11, 1), 'environment')
sleep_quality_ctrl = ctrl.Consequent(np.arange(0, 11, 1), 'sleep_quality')

# Automatically populate membership functions for antecedents
rhythm_ctrl.automf(5)
stress_ctrl.automf(5)
duration_ctrl.automf(5)
environment_ctrl.automf(5)

# Define custom membership functions for the consequent (sleep quality)
sleep_quality_ctrl['poor'] = fuzz.trimf(sleep_quality_ctrl.universe, [0, 0, 2.5])
sleep_quality_ctrl['mediocre'] = fuzz.trimf(sleep_quality_ctrl.universe, [0, 2.5, 5])
sleep_quality_ctrl['average'] = fuzz.trimf(sleep_quality_ctrl.universe, [2.5, 5, 7.5])
sleep_quality_ctrl['decent'] = fuzz.trimf(sleep_quality_ctrl.universe, [5, 7.5, 10])
sleep_quality_ctrl['good'] = fuzz.trimf(sleep_quality_ctrl.universe, [7.5, 10, 10])

# Define fuzzy rules
# Rules for poor sleep quality
rule1 = ctrl.Rule(stress_ctrl['poor'] | environment_ctrl['poor'] | rhythm_ctrl['poor'], sleep_quality_ctrl['poor'])
rule2 = ctrl.Rule(duration_ctrl['poor'] & stress_ctrl['poor'], sleep_quality_ctrl['poor'])
rule3 = ctrl.Rule(environment_ctrl['poor'] & rhythm_ctrl['mediocre'], sleep_quality_ctrl['poor'])

# Rules for mediocre sleep quality
rule4 = ctrl.Rule(stress_ctrl['mediocre'] | environment_ctrl['mediocre'] | duration_ctrl['mediocre'], sleep_quality_ctrl['mediocre'])
rule5 = ctrl.Rule(rhythm_ctrl['mediocre'] & duration_ctrl['mediocre'], sleep_quality_ctrl['mediocre'])
rule6 = ctrl.Rule(environment_ctrl['mediocre'] & (stress_ctrl['poor'] | rhythm_ctrl['poor']), sleep_quality_ctrl['mediocre'])

# Rules for average sleep quality
rule7 = ctrl.Rule(stress_ctrl['average'] & duration_ctrl['average'], sleep_quality_ctrl['average'])
rule8 = ctrl.Rule(rhythm_ctrl['average'] & environment_ctrl['average'], sleep_quality_ctrl['average'])
rule9 = ctrl.Rule(duration_ctrl['average'] & rhythm_ctrl['decent'], sleep_quality_ctrl['average'])
rule10 = ctrl.Rule(environment_ctrl['average'] & (stress_ctrl['average'] | duration_ctrl['average']), sleep_quality_ctrl['average'])

# Rules for decent sleep quality
rule11 = ctrl.Rule((stress_ctrl['decent'] | duration_ctrl['decent']) & (environment_ctrl['average'] | rhythm_ctrl['decent']), sleep_quality_ctrl['decent'])
rule12 = ctrl.Rule(duration_ctrl['decent'] & rhythm_ctrl['good'], sleep_quality_ctrl['decent'])
rule13 = ctrl.Rule(stress_ctrl['decent'] & environment_ctrl['decent'], sleep_quality_ctrl['decent'])

# Rules for good sleep quality
rule14 = ctrl.Rule(rhythm_ctrl['good'] & duration_ctrl['good'] & stress_ctrl['good'], sleep_quality_ctrl['good'])
rule15 = ctrl.Rule(environment_ctrl['good'] & rhythm_ctrl['good'], sleep_quality_ctrl['good'])
rule16 = ctrl.Rule(stress_ctrl['decent'] & duration_ctrl['good'] & environment_ctrl['good'], sleep_quality_ctrl['good'])
rule17 = ctrl.Rule(duration_ctrl['good'] & environment_ctrl['good'], sleep_quality_ctrl['good'])

# Additional rules for beneficial combinations
rule18 = ctrl.Rule(stress_ctrl['decent'] & rhythm_ctrl['good'], sleep_quality_ctrl['good'])
rule19 = ctrl.Rule(duration_ctrl['good'] | (rhythm_ctrl['good'] & environment_ctrl['good']), sleep_quality_ctrl['good'])

# Create a control system and simulation
sleep_quality_control_system = ctrl.ControlSystem([
    rule1, rule2, rule3, rule4, rule5, rule6, rule7, rule8, rule9, rule10,
    rule11, rule12, rule13, rule14, rule15, rule16, rule17, rule18, rule19
])
sleep_quality_simulation = ctrl.ControlSystemSimulation(sleep_quality_control_system)

# Input data model
class InputData(BaseModel):
    rhythm: float
    stress: float
    duration: float
    environment: float

# Fuzzy Logic Function to compute sleep quality
def compute_sleep_quality(rhythm, stress, duration, environment):
    # Input values for the fuzzy simulation
    sleep_quality_simulation.input['rhythm'] = rhythm
    sleep_quality_simulation.input['stress'] = stress
    sleep_quality_simulation.input['duration'] = duration
    sleep_quality_simulation.input['environment'] = environment

    # Perform the computation
    sleep_quality_simulation.compute()

    # Return the resulting sleep quality value
    return sleep_quality_simulation.output['sleep_quality']

# API endpoint to receive data and compute sleep quality
@app.post("/compute_sleep_quality/")
async def compute(input_data: InputData):
    print(f"Received input data: {input_data.dict()}")
    result = compute_sleep_quality(
        input_data.rhythm, input_data.stress, input_data.duration, input_data.environment
    )
    return {"sleep_quality": result}
