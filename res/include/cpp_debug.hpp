#pragma once
#include <iostream>
#include <sys/cdefs.h>
#include <vector>
#include <sstream>
#include <algorithm>
#include <iomanip>
#include <typeinfo>

#ifdef __GNUG__
#include <memory>
#include <cxxabi.h>
inline std::string demangle(const char* name)
{
    int status = -4; // some arbitrary value to eliminate the compiler warning

    // enable c++11 by passing the flag -std=c++11 to g++
    std::unique_ptr<char, void(*)(void*)> res {
        abi::__cxa_demangle(name, NULL, NULL, &status),
        std::free
    };

    return (status==0) ? res.get() : name ;
}
#else
std::string demangle(const char* name) { return name; }
#endif

inline bool mds_string_is_rvalue(std::string varname)
{
    if (!varname.empty()) {
        return varname.front() == '"';
    }
    return false;
}

template <typename Variable>
inline bool mds_is_string(Variable&& variable)
{
    return demangle(typeid(std::forward<Variable>(variable)).name()).find("basic_string") != std::string::npos;
}

template <typename AnyType>
inline void mds_print_vec(std::ostream& out, AnyType&& vec)
{
    out << vec << ", ";
}

template <typename VectorType>
inline void mds_print_vec(std::ostream& out, std::vector<VectorType> vec)
{
    for (uint32_t i = 0u; i < vec.size(); ++i) {
        mds_print_vec(out, vec[i]);
    }
    out << '\n';
}

template <typename Value>
void mds_print_vars(std::ostream& out, const std::string& varname, Value&& value)
{
    if (mds_string_is_rvalue(varname)) {
        out << varname.substr(1, varname.size()-2) << ", ";
    } else if (mds_is_string(value)) {
        out << varname << " = \"" << value << "\", ";
    } else {
        out << varname << " = " << value << ", ";
    }
}

template <typename VectorType>
void mds_print_vars(std::ostream& out, const std::string& varname, std::vector<VectorType> vec)
{
    out << "\nVector [" << varname << "]\n";
    mds_print_vec(out, vec);
}

inline void mds_debug(std::ostream& out, __attribute_maybe_unused__ std::vector<std::string>::const_iterator varnames)
{
    out << std::endl;
}

template <typename Arg, typename... Args>
void mds_debug(std::ostream& out, std::vector<std::string>::const_iterator varnames_iter, Arg&& arg, Args&&... args)
{
    mds_print_vars(out, *varnames_iter, std::forward<Arg>(arg));
    mds_debug(out, ++varnames_iter, std::forward<Args>(args)...);
}

template <typename Arg, typename... Args>
void mds_debug(std::ostream& out, int line_number, Arg&& arg, Args&&... args)
{
    std::stringstream ss(std::forward<Arg>(arg));
    std::vector<std::string> varnames;
    for (std::string var; getline(ss, var, ','); varnames.push_back(var)) {
        if (var.at(0) == ' ') var.erase(0, 1);
    }
    out << std::setw(3) << std::setfill(' ') << std::right << line_number << " - Debug => ";
    mds_debug(out, varnames.begin(), std::forward<Args>(args)...);
}

#define debug(...) mds_debug(cerr, __LINE__, #__VA_ARGS__, __VA_ARGS__);
