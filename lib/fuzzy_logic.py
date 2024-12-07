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
    allow_origins=["*"],  # Replace "*" with specific origins if needed, e.g., ["http://localhost:8080"]
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)


# Input data model
class InputData(BaseModel):
    rhythm: float
    stress: float
    duration: float
    environment: float

# Fuzzy Logic Function to compute sleep quality
def compute_sleep_quality(rhythm, stress, duration, environment):
    # Define fuzzy logic variables (use distinct names)
    rhythm_ctrl = ctrl.Antecedent(np.arange(0, 11, 1), 'rhythm')
    stress_ctrl = ctrl.Antecedent(np.arange(0, 11, 1), 'stress')
    duration_ctrl = ctrl.Antecedent(np.arange(0, 11, 1), 'duration')
    environment_ctrl = ctrl.Antecedent(np.arange(0, 11, 1), 'environment')
    sleep_quality_ctrl = ctrl.Consequent(np.arange(0, 11, 1), 'sleep_quality')

    # Automf for the inputs
    rhythm_ctrl.automf(5)
    stress_ctrl.automf(5)
    duration_ctrl.automf(5)
    environment_ctrl.automf(5)

    # Membership functions for sleep quality
    sleep_quality_ctrl['poor'] = fuzz.trimf(sleep_quality_ctrl.universe, [0, 0, 2.5])
    sleep_quality_ctrl['mediocre'] = fuzz.trimf(sleep_quality_ctrl.universe, [0, 2.5, 5])
    sleep_quality_ctrl['average'] = fuzz.trimf(sleep_quality_ctrl.universe, [2.5, 5, 7.5])
    sleep_quality_ctrl['decent'] = fuzz.trimf(sleep_quality_ctrl.universe, [5, 7.5, 10])
    sleep_quality_ctrl['good'] = fuzz.trimf(sleep_quality_ctrl.universe, [7.5, 10, 10])

    # Calculate the sleep quality based on fuzzy rules (simplified for demonstration)
    sleep_quality_value = np.mean([rhythm, stress, duration, environment])  # Use numeric inputs directly
    return sleep_quality_value

# API endpoint to receive data and compute sleep quality
@app.post("/compute_sleep_quality/")
async def compute(input_data: InputData):
    print(f"Received input data: {input_data.dict()}")
    result = compute_sleep_quality(
        input_data.rhythm, input_data.stress, input_data.duration, input_data.environment
    )
    return {"sleep_quality": result}
