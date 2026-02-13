import logging
import sys
from hyperon import *
from hyperon.ext import register_atoms
from hyperon.atoms import SymbolAtom, ValueAtom, ExpressionAtom

LOG_FILE_NAME = 'metta_events.log'
LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
CONSOLE_LOG_LEVEL = logging.DEBUG
FILE_LOG_LEVEL = logging.INFO
LOGGER_NAME = 'MeTTaLogger'

logger = logging.getLogger(LOGGER_NAME)
logger.setLevel(logging.DEBUG)

console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(CONSOLE_LOG_LEVEL)
console_formatter = logging.Formatter(LOG_FORMAT)
console_handler.setFormatter(console_formatter)
if not any(isinstance(h, logging.StreamHandler) for h in logger.handlers):
    logger.addHandler(console_handler)
    try:
        file_handler = logging.FileHandler(LOG_FILE_NAME)
        file_handler.setLevel(FILE_LOG_LEVEL)
        file_formatter = logging.Formatter(LOG_FORMAT)
        file_handler.setFormatter(file_formatter)
        logger.addHandler(file_handler)
        logger.info(f"--- Logger initialized. Logging to console (level {logging.getLevelName(CONSOLE_LOG_LEVEL)}) and file '{LOG_FILE_NAME}' (level {logging.getLevelName(FILE_LOG_LEVEL)}) ---")
    except Exception as e:
        logger.error(f"Failed to initialize file handler for {LOG_FILE_NAME}: {e}")
        print(f"ERROR: Failed to initialize file handler for {LOG_FILE_NAME}: {e}", file=sys.stderr)


def format_modulator_change(name: str, old_value: str, new_value: str) -> str:
    try:
        diff = float(new_value) - float(old_value)
        return f"[MODULATOR_UPDATE]-{name} {old_value}' -> {new_value}   diff={diff}"
    except ValueError:
        return f"[MODULATOR_UPDATE]-{name} {old_value}' -> {new_value}"


def format_feeling_update(feeling_name: str, old_value: str, new_value: str) -> str:
    return f"[FEELING_UPDATE]-{feeling_name} {old_value}' -> {new_value}  "


def format_schema_update(schema_id: str, update_type: str, details: str) -> str:
    return f"[SCHEMA_UPDATE]-{schema_id} {update_type} {details}"


# New logging wrappers for specific types/levels
def log_modulator_change(name: str, old_value: str, new_value: str) -> str:
    message = format_modulator_change(name, old_value, new_value)
    logger.info(message)
    return message


def log_modulator_debug(name: str, old_value: str, new_value: str) -> str:
    message = format_modulator_change(name, old_value, new_value)
    logger.debug(message)
    return message


def log_feeling_update(feeling_name: str, old_value: str, new_value: str) -> str:
    message = format_feeling_update(feeling_name, old_value, new_value)
    logger.info(message)
    return message


def log_feeling_update_debug(feeling_name: str, old_value: str, new_value: str) -> str:
    message = format_feeling_update(feeling_name, old_value, new_value)
    logger.debug(message)
    return message


def log_schema_update(schema_id: str, update_type: str, details: str) -> str:
    message = format_schema_update(schema_id, update_type, details)
    logger.debug(message)
    return message


EVENT_HANDLERS = {
    "modulator_change": (format_modulator_change, logging.INFO),
    "modulator_debug": (format_modulator_change, logging.DEBUG),
    "feeling_update": (format_feeling_update, logging.INFO),
    "feeling_update_debug": (format_feeling_update, logging.DEBUG),
    "schema_update": (format_schema_update, logging.DEBUG),
}


def log_event(event_type: str, *handler_args: str) -> str:
    try:
        handler_info = EVENT_HANDLERS.get(event_type)

        if handler_info is None:
            msg = f"log-event: No handler found for event type '{event_type}' with args {handler_args}"
            logger.error(msg)
            return msg

        formatter_func, default_level = handler_info

        try:
            message = formatter_func(*handler_args)
        except TypeError as te:
            expected_args_count = formatter_func.__code__.co_argcount
            msg = (f"log-event: Handler for '{event_type}' ({formatter_func.__name__}) "
                   f"called with wrong number of arguments. Expected {expected_args_count}, got {len(handler_args)}. "
                   f"Args: {handler_args}. Error: {te}")
            logger.error(msg)
            return msg
        except Exception as e:
            msg = f"log-event: Error executing handler '{event_type}': {e}"
            logger.error(msg)
            return msg

        logger.log(default_level, message)
        return message

    except Exception as e:
        logger.exception(f"log-event: Unexpected error processing log event: {e}")
        return f"log-event: Exception occurred - {e}"
    
@register_atoms(pass_metta=True)
def register_logger_atoms(metta):
    log_event_atom = OperationAtom(
        "log-event",
        lambda event_type, payload_expr: log_event(metta, event_type, payload_expr),
        ["Atom", "Expression", "Expression"],
        unwrap=False,
    )
    logger.info("`log-event` operation registered for MeTTa.")
    return {"log-event": log_event_atom}