# encoding: UTF-8

module Decider
  class TrainingSet
    attr_reader :documents
    
    def initialize
      @tokens = {}
      @documents = []
    end
    
    def <<(group_of_tokens)
      invalidate_cache
      
      @documents << Document.new(self, group_of_tokens.to_a)
      
      group_of_tokens.to_a.each do |token|
        if @tokens.has_key?(token)
          @tokens[token].increment
        else
          @tokens[token] = Token.new(token, :index => @tokens.length)
        end
      end
      self
    end
    
    def tokens
      @token_values ||= @tokens.keys
    end
    
    def index_of(token)
      if token = @tokens[token]
        token.index
      end
    end
    
    def count_of(token)
      @tokens[token].count
    end
    
    def vectorize(tokens)
      vector = Array.new(@tokens.length, 0)
      tokens.each do |token| 
        if index = index_of(token)
          vector[index] = 1
        end
      end
      vector
    end
    
    def probability_of_token(token)
      if token = @tokens[token]
        token.count.to_f / total_tokens.to_f
      else
        hapax_occurrence_value / total_tokens.to_f
      end
    end
    
    def probability_of_tokens(tokens)
      (tokens.inject(0) { |sum, token| sum + probability_of_token(token) }) / tokens.count.to_f
    end
    
    def total_tokens
      @token_count ||= @tokens.inject(0) { |sum, key_val| sum + key_val.last.count }
    end
    
    def probabilities_of_documents
      @documents.map { |d| d.probability }
    end
    
    def avg_document_probability
      @avg_document_probability ||= probabilities_of_documents.inject(0) { |sum, prob| sum + prob } / @documents.count.to_f
    end
    
    def document_score_stddev
      @document_score_stddev ||= Math.stddev(probabilities_of_documents)
    end
    
    def distance_from_avg_in_stddevs(tokens)
      (probability_of_tokens(tokens) - avg_document_probability) / document_score_stddev
    end
    
    def anomaly_score_of(tokens)
      @anomaly_score_of_tokens ||= {}
      if result = @anomaly_score_of_tokens[tokens]
        result
      else
        number_std_devs = distance_from_avg_in_stddevs(tokens)
        @anomaly_score_of_tokens[tokens] = number_std_devs > 0 ? 0 : -1.0 * number_std_devs
      end
    end
    
    def hapax_occurrence_value
      0
    end
    
    private
    
    def invalidate_cache
      @token_values = nil
      @token_count = nil
      @document_score_stddev = nil
      @anomaly_score_of_tokens = nil
      @avg_document_probability = nil
    end
    
    public
    
    class Document
      attr_reader :training_set, :tokens

      def initialize(training_set, *tokens)
        @training_set, @tokens = training_set, tokens.flatten
      end
      
      def probability
        @training_set.probability_of_tokens(@tokens)
      end

    end
    
  end
  
end
