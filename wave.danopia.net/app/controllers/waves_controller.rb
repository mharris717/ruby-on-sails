class WavesController < ApplicationController
	before_filter :require_user, :connect_remote

  def index
		@address = "#{current_user.login}@newwave.danopia.net"
		@waves = @remote.all_waves
  end

  def show
		@address = "#{current_user.login}@newwave.danopia.net"
		
		if params[:id] == 'new'
			@wave = Wave.new(@remote.provider, random_name)
			@remote << @wave
    	redirect_to wave_path(@wave.name)
			return
		end
		
		@wave = @remote[params[:id]]
		
		unless @wave.participants.include? @address
			delta = Delta.new @wave, @address
			delta.operations << AddUserOp.new(@address)
    	@remote.add_delta @wave, delta
    	
			delta = Delta.new @wave, @address
			delta.operations << MutateOp.new('main', create_fedone_line(@address, "Hey there, this is #{@address}, and I'm using Ruby on Sails!", @wave))
    	@remote.add_delta @wave, delta
    end
    
  end

  def update
		@address = "#{current_user.login}@newwave.danopia.net"
		
		@wave = @remote[params[:id]]
		
		if @wave.participants.include? @address
			delta = Delta.new @wave, @address
			delta.operations << MutateOp.new('main', create_fedone_line(@address, params[:message], @wave))
    	@remote.add_delta(@wave, delta)
    	flash[:notice] = "Your message has been added."
    else
    	flash[:error] = 'fail.'
    end
    
    redirect_to wave_path(@wave.name)
  end

  def remove
		@address = "#{current_user.login}@newwave.danopia.net"
		@wave = @remote[params[:id]]
		
		if !@wave.participants.include? @address
    	flash[:error] = 'fail.'
		elsif !( params[:who] && @wave.participants.include?(params[:who]) )
    	flash[:error] = "#{params[:who]} isn't in this wave."
    else
			delta = Delta.new @wave, @address
			delta.operations << RemoveUserOp.new(params[:who])
    	@remote.add_delta(@wave, delta)
    	flash[:notice] = "#{params[:who]} has been removed from the wave."
    end
    
    redirect_to wave_path(@wave.name)
  end

  def add
		@address = "#{current_user.login}@newwave.danopia.net"
		@wave = @remote[params[:id]]
		
		if !@wave.participants.include? @address
    	flash[:error] = 'fail.'
		elsif !params[:who] || @wave.participants.include?(params[:who])
    	flash[:error] = "#{params[:who]} is already in this wave."
    else
			delta = Delta.new @wave, @address
			delta.operations << AddUserOp.new(params[:who])
    	@remote.add_delta(@wave, delta)
    	flash[:notice] = "#{params[:who]} has been added to the wave."
    end
    
    redirect_to wave_path(@wave.name)
  end

	protected
	
	def create_fedone_line(author, text, wave)
		if wave.item_count > 0
			[{:retain_item_count=>wave.item_count},
			 {:element_start=>
				{:type=>"line",
				 :attributes=>
					[{:value=>author, :key=>"by"}]}},
			 {:element_end=>true},
			 {:characters=>text}]
		else
			[{:element_start=>
				{:type=>"line",
				 :attributes=>
					[{:value=>author, :key=>"by"}]}},
			 {:element_end=>true},
			 {:characters=>text}]
		end
	end
	
	def connect_remote
		return if @remote
		@remote = SailsRemote.connect
		DRb.start_service
	end
	
	def random_name(length=12)
		@letters ||= ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
		([''] * length).map { @letters[rand * @letters.size] }.join('')
	end
end
