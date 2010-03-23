#include<pin.h>

pin::pin(void)
{
	_pin    = 0;
	_pinDir = INPUT;
	_mask = 0x00;
}

pin::pin(byte p)
{
	_pinDir = INPUT;
	_mask = 0x00;
	this->setup(p,INPUT);
}

pin::pin(byte p, byte dir)
{
	_mask = 0x00;
	this->setup(p , dir);
}

void pin::setup(byte p, byte dir)
{

	if( p > _P_MAX)
		return;


	_pinDir = dir;
	_pin = p;
	_mask = 0x00;

	if(_PA(_pin))
	{
		_mask = _PA_MASK(_pin);
		if(_pinDir == OUTPUT)
			DDRA |= _mask;
		else
			DDRA &= ~_mask;
		_port=PA;
		return;
	}

	else if(_PB(_pin))
	{
		_mask = _PB_MASK(_pin);
		if(_pinDir == OUTPUT)
			DDRB |= _mask;
		else
			DDRB &= ~_mask;
		_port=PB;
		return;
	}

	else if(_PC(_pin))
	{
		_mask = _PC_MASK(_pin);
		if(_pinDir == OUTPUT)
			DDRC |= _mask;
		else
			DDRC &= ~_mask;
		_port=PC;
		return;
	}
	else if(_PD(_pin))
	{
		_mask = _PD_MASK(_pin);
		if(_pinDir == OUTPUT)
			DDRD |= _mask;
		else
			DDRD &= ~_mask;
		_port=PD;
		return;
	}
	return;
}

void pin::set(void)
{
	switch(_port)
	{
	case PD:
		{
			PORTD |= _mask;
			break;
		}

	case PB:
		{
			PORTB |= _mask;
			break;
		}
	
	case PC:
		{
			PORTC |= _mask;
			break;
		}

	case PA:
		{
			PORTA |= _mask;
			break;
		}

	defualt:
			break;
	}
	return;
}

void pin::clear(void)
{
	switch(_port)
	{
	case PD:
		{
			PORTD &= ~_mask;
			break;
		}

	case PB:
		{
			PORTB &= ~_mask;
			break;
		}
	
	case PC:
		{
			PORTC &= ~_mask;
			break;
		}

	case PA:
		{
			PORTA &= ~_mask;
			break;
		}

	default:
			break;
	}
	return;
}

void pin::set(byte state)
{
	if (_pinDir == INPUT)
		return;

	if(state == HIGH)
		this->set();
	else
		this->clear();
}


byte pin::get(void)
{
	switch(_port)
	{
	case PD:
		{
			return((PIND & _mask)?0xFF:0x0);
			break;
		}
	case PB:
		{
			return((PINB & _mask)?0xFF:0x0);
			break;
		}

	case PC:
		{
			return((PINC & _mask)?0xFF:0x0);
			break;
		}
	case PA:
		{
			return((PINA & _mask)?0xFF:0x0);
			break;
		}
	default :
		break;
	}
	return(0);
}

void pin::setDir(byte dir)
{
	_pinDir = dir;
	this->setup(_pin,_pinDir);
}

byte pin::getDir(void)
{
	return(_pinDir);
}

void pin::setPin(byte p)
{
	_pin = p;
	this->setup(_pin, _pinDir);
}

byte pin::getPin(void)
{
	return(_pin);
}