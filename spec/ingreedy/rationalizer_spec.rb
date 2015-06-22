require 'spec_helper'

describe Ingreedy::Rationalizer do
  subject { described_class }

  context 'with an integer and a fraction' do
    it 'should give back an improper rational' do
      subject.rationalize(integer: '1', fraction: '1/2').should == '3/2'.to_r
    end
  end

  context 'with a fraction' do
    it 'should give back a rational' do
      subject.rationalize(fraction: '1/2').should == '1/2'.to_r
    end
  end

  context 'with an integer' do
    it 'should give back a rational' do
      subject.rationalize(integer: '2').should == '2'.to_r
    end
  end

  context 'with a float' do
    it 'should give back a rational' do
      subject.rationalize(float: '0.3').should == '3/10'.to_r
    end
  end

  context 'with a european float' do
    it 'should give back a rational' do
      subject.rationalize(float: '0,4').should == '4/10'.to_r
    end
  end

  context 'with an english digit' do
    it 'gives back a rational' do
      subject.rationalize(word: 'one').should == '1'.to_r
    end
  end

  context 'with the word a or an' do
    it 'gives back a rational' do
      subject.rationalize(word: 'a').should == '1'.to_r
      subject.rationalize(word: 'AN').should == '1'.to_r
    end
  end

end

