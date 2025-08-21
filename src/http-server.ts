/**
 * HTTP Server implementation for FRED MCP Server
 * Exposes MCP tools as REST API endpoints with JSON responses
 */
import express, { Request, Response } from 'express';
import cors from 'cors';
import { createServer } from './index.js';
import { searchSeries } from './fred/search.js';
import { getSeriesData } from './fred/series.js';
import { browseCategories, getCategorySeries, browseReleases, getReleaseSeries, browseSources } from './fred/browse.js';

const app = express();
const port = parseInt(process.env.PORT || '3000', 10);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.json({ 
    status: 'healthy', 
    service: 'FRED MCP Server',
    timestamp: new Date().toISOString()
  });
});

// Info endpoint
app.get('/', (req: Request, res: Response) => {
  res.json({
    name: 'FRED MCP Server HTTP API',
    description: 'Access to Federal Reserve Economic Data through REST API',
    version: '1.0.0',
    endpoints: {
      browse: '/api/browse',
      search: '/api/search', 
      series: '/api/series/:seriesId'
    },
    documentation: 'https://github.com/stefanoamorelli/fred-mcp-server'
  });
});

// Browse endpoint
app.post('/api/browse', async (req: Request, res: Response) => {
  try {
    const { browse_type, category_id, release_id, limit = 50, offset = 0, order_by, sort_order } = req.body;
    
    if (!browse_type) {
      return res.status(400).json({ 
        error: 'browse_type is required',
        valid_types: ['categories', 'releases', 'sources', 'category_series', 'release_series']
      });
    }

    let result;
    switch (browse_type) {
      case 'categories':
        result = await browseCategories(category_id);
        break;
      case 'category_series':
        if (!category_id) {
          return res.status(400).json({ error: 'category_id is required for category_series' });
        }
        result = await getCategorySeries(category_id, { limit, offset, order_by, sort_order });
        break;
      case 'releases':
        result = await browseReleases({ limit, offset, order_by, sort_order });
        break;
      case 'release_series':
        if (!release_id) {
          return res.status(400).json({ error: 'release_id is required for release_series' });
        }
        result = await getReleaseSeries(release_id, { limit, offset, order_by, sort_order });
        break;
      case 'sources':
        result = await browseSources({ limit, offset, order_by, sort_order });
        break;
      default:
        return res.status(400).json({ error: `Invalid browse_type: ${browse_type}` });
    }

    res.json(result);
  } catch (error) {
    console.error('Browse error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Search endpoint
app.post('/api/search', async (req: Request, res: Response) => {
  try {
    const searchOptions = {
      search_text: req.body.search_text,
      search_type: req.body.search_type,
      tag_names: req.body.tag_names,
      exclude_tag_names: req.body.exclude_tag_names,
      limit: req.body.limit || 25,
      offset: req.body.offset || 0,
      order_by: req.body.order_by,
      sort_order: req.body.sort_order,
      filter_variable: req.body.filter_variable,
      filter_value: req.body.filter_value
    };

    const result = await searchSeries(searchOptions);
    res.json(result);
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Get series data endpoint
app.get('/api/series/:seriesId', async (req: Request, res: Response) => {
  try {
    const { seriesId } = req.params;
    const {
      observation_start,
      observation_end,
      limit,
      offset,
      sort_order,
      units,
      frequency,
      aggregation_method,
      output_type,
      vintage_dates
    } = req.query;

    const parseOutputType = (value: string): 1 | 2 | 3 | 4 | undefined => {
      if (!value) return undefined;
      const parsed = parseInt(value);
      return [1, 2, 3, 4].includes(parsed) ? (parsed as 1 | 2 | 3 | 4) : undefined;
    };

    const seriesOptions = {
      series_id: seriesId,
      observation_start: observation_start as string,
      observation_end: observation_end as string,
      limit: limit ? parseInt(limit as string) : undefined,
      offset: offset ? parseInt(offset as string) : undefined,
      sort_order: sort_order as any,
      units: units as any,
      frequency: frequency as any,
      aggregation_method: aggregation_method as any,
      output_type: parseOutputType(output_type as string),
      vintage_dates: vintage_dates as string
    };

    const result = await getSeriesData(seriesOptions);
    res.json(result);
  } catch (error) {
    console.error('Series data error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// POST version of series endpoint for complex queries
app.post('/api/series', async (req: Request, res: Response) => {
  try {
    const { series_id, ...options } = req.body;
    
    if (!series_id) {
      return res.status(400).json({ error: 'series_id is required' });
    }

    const result = await getSeriesData({ series_id, ...options });
    res.json(result);
  } catch (error) {
    console.error('Series data error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Error handling middleware
app.use((error: Error, req: Request, res: Response, next: any) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    message: error.message 
  });
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({ 
    error: 'Not found',
    path: req.path,
    available_endpoints: [
      'GET /',
      'GET /health',
      'POST /api/browse',
      'POST /api/search',
      'GET /api/series/:seriesId',
      'POST /api/series'
    ]
  });
});

// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`FRED HTTP Server running on port ${port}`);
  console.log(`API Documentation available at http://localhost:${port}`);
  
  // Validate FRED API key
  if (!process.env.FRED_API_KEY) {
    console.warn('⚠️  WARNING: FRED_API_KEY environment variable not set');
    console.warn('   Get your API key from: https://fred.stlouisfed.org/docs/api/api_key.html');
  }
});

export { app };
