"""
PID Decoder Service
Decodes OBD-II Parameter IDs (PIDs)
"""

import math
from decimal import Decimal


class PIDDecoder:
    """Service for decoding OBD-II PIDs"""

    # Standard OBD-II PID definitions
    PID_DEFINITIONS = {
        '0100': {'name': 'Supported PIDs 1-20', 'unit': '', 'formula': 'hex'},
        '0101': {'name': 'Monitor status since DTCs cleared', 'unit': '', 'formula': 'hex'},
        '0102': {'name': 'Freeze DTC', 'unit': '', 'formula': 'hex'},
        '0103': {'name': 'Fuel system status', 'unit': '', 'formula': 'hex'},
        '0104': {'name': 'Engine load', 'unit': '%', 'formula': 'A*100/255'},
        '0105': {'name': 'Engine coolant temperature', 'unit': '°C', 'formula': 'A-40'},
        '0106': {'name': 'Short term fuel trim - Bank 1', 'unit': '%', 'formula': '(A-128)*100/128'},
        '0107': {'name': 'Long term fuel trim - Bank 1', 'unit': '%', 'formula': '(A-128)*100/128'},
        '0108': {'name': 'Short term fuel trim - Bank 2', 'unit': '%', 'formula': '(A-128)*100/128'},
        '0109': {'name': 'Long term fuel trim - Bank 2', 'unit': '%', 'formula': '(A-128)*100/128'},
        '010A': {'name': 'Fuel pressure', 'unit': 'kPa', 'formula': 'A*3'},
        '010B': {'name': 'Intake manifold absolute pressure', 'unit': 'kPa', 'formula': 'A'},
        '010C': {'name': 'Engine RPM', 'unit': 'rpm', 'formula': '(A*256+B)/4'},
        '010D': {'name': 'Vehicle speed', 'unit': 'km/h', 'formula': 'A'},
        '010E': {'name': 'Timing advance', 'unit': '°', 'formula': '(A-128)*0.5'},
        '010F': {'name': 'Intake air temperature', 'unit': '°C', 'formula': 'A-40'},
        '0110': {'name': 'MAF air flow rate', 'unit': 'g/s', 'formula': '(A*256+B)/100'},
        '0111': {'name': 'Throttle position', 'unit': '%', 'formula': 'A*100/255'},
        '0112': {'name': 'Secondary air status', 'unit': '', 'formula': 'hex'},
        '0113': {'name': 'O2 sensors present', 'unit': '', 'formula': 'hex'},
        '0114': {'name': 'O2 Sensor 1 - Bank 1', 'unit': 'V', 'formula': 'A/200'},
        '0115': {'name': 'O2 Sensor 2 - Bank 1', 'unit': 'V', 'formula': 'A/200'},
        '0116': {'name': 'O2 Sensor 3 - Bank 1', 'unit': 'V', 'formula': 'A/200'},
        '0117': {'name': 'O2 Sensor 4 - Bank 1', 'unit': 'V', 'formula': 'A/200'},
        '0118': {'name': 'O2 Sensor 1 - Bank 2', 'unit': 'V', 'formula': 'A/200'},
        '0119': {'name': 'O2 Sensor 2 - Bank 2', 'unit': 'V', 'formula': 'A/200'},
        '011A': {'name': 'O2 Sensor 3 - Bank 2', 'unit': 'V', 'formula': 'A/200'},
        '011B': {'name': 'O2 Sensor 4 - Bank 2', 'unit': 'V', 'formula': 'A/200'},
        '011C': {'name': 'OBD standards this vehicle conforms to', 'unit': '', 'formula': 'hex'},
        '011D': {'name': 'O2 sensors present', 'unit': '', 'formula': 'hex'},
        '011E': {'name': 'Auxiliary input status', 'unit': '', 'formula': 'hex'},
        '011F': {'name': 'Run time since engine start', 'unit': 's', 'formula': 'A*256+B'},
    }

    @staticmethod
    def decode(pid, data):
        """Decode a PID value"""
        pid_upper = pid.upper()
        definition = PIDDecoder.PID_DEFINITIONS.get(pid_upper)

        if not definition:
            return {
                'name': f'Unknown PID: {pid}',
                'value': data,
                'unit': '',
                'formula': 'raw',
            }

        try:
            # Parse data
            if isinstance(data, str):
                data = data.replace(' ', '').replace('0x', '')
                if len(data) >= 2:
                    values = [int(data[i:i+2], 16) for i in range(0, len(data), 2)]
                else:
                    values = [int(data, 16)]
            elif isinstance(data, list):
                values = data
            else:
                values = [data]

            formula = definition.get('formula', '')
            result = PIDDecoder._apply_formula(formula, values)

            return {
                'name': definition['name'],
                'value': result,
                'unit': definition.get('unit', ''),
                'formula': formula,
                'raw_data': data,
            }
        except Exception:
            return {
                'name': definition['name'],
                'value': data,
                'unit': definition.get('unit', ''),
                'formula': 'error',
                'raw_data': data,
            }

    @staticmethod
    def _apply_formula(formula, values):
        """Apply formula to values"""
        if not formula or formula == 'raw':
            return values[0] if values else None

        if formula == 'hex':
            return ' '.join([f'{v:02X}' for v in values])

        try:
            # Create a namespace with values A, B, C, D...
            namespace = {}
            for i, v in enumerate(values):
                namespace[chr(65 + i)] = v  # A, B, C, D...

            # Evaluate formula safely
            result = eval(formula, {"__builtins__": {}}, namespace)
            return round(result, 4) if isinstance(result, float) else result
        except Exception:
            return values[0] if values else None

    @staticmethod
    def get_common_pids():
        """Get list of common PIDs"""
        return list(PIDDecoder.PID_DEFINITIONS.keys())

    @staticmethod
    def get_pid_info(pid):
        """Get information about a PID"""
        pid_upper = pid.upper()
        definition = PIDDecoder.PID_DEFINITIONS.get(pid_upper)

        if not definition:
            return None

        return {
            'pid': pid_upper,
            'name': definition.get('name'),
            'unit': definition.get('unit'),
            'formula': definition.get('formula'),
        }
