#  Add methods to Enumerable, which makes them available to Array
module Enumerable
  #  sum of an array of numbers
  def sum
    return self.inject(0){|acc,i|acc +i}
  end
 
  #  mean of an array of numbers
  def mean
    return self.sum/self.length.to_f
  end
 
  #  variance of an array of numbers
  def sample_variance
    mean=self.mean
    sum=self.inject(0){|acc,i|acc +(i-mean)**2}
    return(1/self.length.to_f*sum)
  end
 
  #  standard deviation of an array of numbers
  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end
 
end
