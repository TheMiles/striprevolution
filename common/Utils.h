// -*- mode: c++ -*-
#ifndef UTILS_H
#define UTILS_H

template< class T >
T min(const T& a, const T& b)
{
	return (a<b) ? a : b;
}

template< typename T >
T max( const T& a, const T& b)
{
	return (a>b) ? a : b;
}


#endif //UTILS_H