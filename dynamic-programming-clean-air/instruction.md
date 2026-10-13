# Task: Output and clean air (computational exercise)

*Originally a timed data task. The questions are reproduced below. There is no external data set: the exercise is purely computational.*

## Setup

A government is trying to maximize output while considering the world's environmental quality. After every year, there is a probability β = 0.05 that the government is fired and ceases to operate. The government values output according to the utility function

$$U(Y_t) = \log(1 + Y_t).$$

The stock of clean air follows the law of motion

$$S_{t+1} = (1 + \tau) S_t - \delta_t Y_t,$$

where τ = 0.01 is the regeneration parameter of clean air and δ<sub>t</sub> is the environmental damage that one unit of production has on clean air.

The damage δ<sub>t</sub> is a random variable, so the impact of production on clean air is not constant. The damage parameter can be either high (δ<sub>t</sub> = 1) or low (δ<sub>t</sub> = 0.8). Every year, there is a 20% probability that the damage parameter changes: if the damage is currently δ<sub>t</sub> = 1, there is an 80% probability that it will also be high next year and a 20% probability that it will be low next year (and vice versa). For the first year, δ<sub>t</sub> = 1.

The government starts with S<sub>t</sub> = 100 and, once S<sub>t</sub> = 0, the government stops operating. The government wants to maximize the sum of utility it generates from output over time, weighted by the probability of still being in power in a given year.

## Questions

1. Write this as a dynamic programming problem in recursive form. What are the choice variable(s) in this problem? What are the state variable(s)? What is the conceptual difference between the two?
2. Take first-order conditions. Use the envelope theorem to get the optimality conditions in observables.
3. Combine the optimality conditions to obtain the Euler equation and write the transversality condition. Provide a brief interpretation of these equations in the context of the problem.
4. Write code to solve this dynamic program. Plot the value function as a function of the remaining stock of clean air.
5. Create a simulation round showing the random draws of δ, the output the government produces in each period, and the stock of clean air.
